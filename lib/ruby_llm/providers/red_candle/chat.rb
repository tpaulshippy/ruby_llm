# frozen_string_literal: true

module RubyLLM
  module Providers
    class RedCandle
      # Chat methods for the Red-Candle provider
      module Chat
        def completion_url
          'local://chat/completions'
        end

        def render_payload(messages, model:, tools: nil, temperature: nil, stream: false, schema: nil)
          {
            model: model,
            messages: format_messages(messages),
            temperature: temperature,
            tools: tools,
            stream: stream,
            schema: schema
          }
        end

        def format_messages(messages)
          messages.map do |msg|
            {
              role: msg.role.to_s,
              content: format_content(msg.content)
            }
          end
        end

        def format_messages_for_red_candle(messages)
          messages.map do |msg|
            {
              role: msg[:role].to_sym,
              content: msg[:content].to_s
            }
          end
        end

        def format_content(content)
          case content
          when Array
            # Handle multimodal content (text + images)
            content.map { |part| format_content_part(part) }
          else
            content.to_s
          end
        end

        def format_content_part(part)
          case part.type
          when 'text'
            part.text
          when 'image'
            # Red-Candle doesn't support images in chat yet
            '[Image content not supported in Red-Candle]'
          else
            part.to_s
          end
        end

        def stream_response(_connection, payload, _headers, &)
          llm = get_or_create_model(payload[:model])

          if payload[:schema]
            # Structured generation doesn't support streaming
            result = generate_structured(llm, payload)
            yield build_chunk(result, finished: true)
          else
            stream_chat(llm, payload, &)
          end
        end

        private

        def generate_chat(llm, payload)
          config = build_generation_config(payload)
          messages = format_messages_for_red_candle(payload[:messages])
          llm.chat(messages, config: config)
        end

        def generate_structured(llm, payload)
          config = build_generation_config(payload)
          messages = format_messages_for_red_candle(payload[:messages])

          result = llm.generate_structured(messages, schema: payload[:schema], config: config)
          build_completion_response(result.to_json, payload[:model])
        end

        def stream_chat(llm, payload)
          config = build_generation_config(payload)
          messages = format_messages_for_red_candle(payload[:messages])

          llm.chat_stream(messages, config: config) do |token|
            chunk = build_chunk(token, finished: false)
            yield chunk
          end

          # Send final chunk
          yield build_chunk('', finished: true)
        end

        def build_generation_config(payload)
          config_opts = {}
          config_opts[:temperature] = payload[:temperature] if payload[:temperature]
          config_opts[:max_length] = payload[:max_tokens] if payload[:max_tokens]

          Candle::GenerationConfig.balanced(**config_opts)
        end

        def build_chunk(content, finished:)
          {
            'id' => "redcandle-#{SecureRandom.hex(6)}",
            'object' => 'chat.completion.chunk',
            'created' => Time.now.to_i,
            'model' => 'red-candle',
            'choices' => [
              {
                'index' => 0,
                'delta' => finished ? {} : { 'content' => content },
                'finish_reason' => finished ? 'stop' : nil
              }
            ]
          }
        end

        def build_completion_response(content, model)
          {
            'id' => "redcandle-#{SecureRandom.hex(6)}",
            'object' => 'chat.completion',
            'created' => Time.now.to_i,
            'model' => model,
            'choices' => [
              {
                'index' => 0,
                'message' => {
                  'role' => 'assistant',
                  'content' => content
                },
                'finish_reason' => 'stop'
              }
            ],
            'usage' => {
              'prompt_tokens' => 0,
              'completion_tokens' => 0,
              'total_tokens' => 0
            }
          }
        end
      end
    end
  end
end

# frozen_string_literal: true

module RubyLLM
  module Providers
    module OpenAI
      # Chat methods of the OpenAI API integration
      module Chat
        def completion_url
          'responses'
        end

        module_function

        def render_payload(messages, tools:, temperature:, model:, stream: false)
          payload = {
            model: model,
            input: format_messages(messages),
            stream: stream
          }

          # Only include temperature if it's not nil (some models don't accept it)
          payload[:temperature] = temperature unless temperature.nil?

          if tools.any?
            payload[:tools] = tools.map { |_, tool| tool_for(tool) }
            payload[:tool_choice] = 'auto'
          end

          payload[:stream_options] = { include_usage: true } if stream
          payload
        end

        def parse_completion_response(response)
          data = response.body
          return if data.empty?

          raise Error.new(response, data.dig('error', 'message')) if data.dig('error', 'message')

          message_data = data.dig('choices', 0, 'message')
          return parse_responses_response(data) unless message_data

          Message.new(
            role: :assistant,
            content: message_data['content'],
            tool_calls: parse_tool_calls(message_data['tool_calls']),
            input_tokens: data['usage']['prompt_tokens'],
            output_tokens: data['usage']['completion_tokens'],
            model_id: data['model']
          )
        end

        def parse_responses_response(data)
          outputs = data['output']
          return unless outputs&.any?

          assistant_text = nil
          raw_calls      = []

          outputs.each do |block|
            case block['type']
            when 'text'
              assistant_text ||= block['text']
            when 'message'
              assistant_text ||= extract_content_from_output(block)
            when 'function_call'
              raw_calls << block
            end
          end

          Message.new(
            role: :assistant,
            content: assistant_text,
            tool_calls: parse_tool_calls(raw_calls),
            input_tokens: data['usage']['input_tokens'],
            output_tokens: data['usage']['output_tokens'],
            model_id: data['model']
          )
        end

        def format_messages(messages)
          messages.map do |msg|
            {
              role: format_role(msg.role),
              content: Media.format_content(msg.content),
              tool_calls: format_tool_calls(msg.tool_calls),
              tool_call_id: msg.tool_call_id
            }.compact
          end
        end

        def format_role(role)
          case role
          when :system
            'developer'
          else
            role.to_s
          end
        end

        private

        def parse_tool_calls(raw_calls)
          return nil unless raw_calls&.any?

          raw_calls.to_h do |tc|
            [
              tc['call_id'] || tc['id'],
              ToolCall.new(
                id: tc['call_id'] || tc['id'],
                name: tc['name'],
                arguments: tc['arguments'].is_a?(String) ? JSON.parse(tc['arguments']) : tc['arguments']
              )
            ]
          end
        end

        def extract_content_from_output(message_data)
          content_blocks = message_data['content']
          return nil unless content_blocks&.any?

          text_block = content_blocks.find { |block| block['type'] == 'output_text' }
          text_block&.dig('text')
        end
      end
    end
  end
end

# frozen_string_literal: true

module RubyLLM
  module Providers
    # Red-Candle provider for local AI models
    class RedCandle < Provider
      include RedCandle::Chat
      include RedCandle::Models
      include RedCandle::ModelManagement

      def initialize(config)
        super
        @model_instances = {}
      end

      def api_base
        'local://red-candle'
      end

      def headers
        {}
      end

      def maybe_normalize_temperature(temperature, model)
        RedCandle::Capabilities.normalize_temperature(temperature, model.id)
      end

      class << self
        def capabilities
          RedCandle::Capabilities
        end

        def configuration_requirements
          []
        end

        def local?
          true
        end
      end

      def sync_response(_connection, payload, _headers)
        llm = get_or_create_model(payload[:model])

        response = if payload[:schema]
                     generate_structured(llm, payload)
                   else
                     result = generate_chat(llm, payload)
                     build_completion_response(result, payload[:model])
                   end

        parse_completion_response(response)
      end

      def parse_completion_response(response)
        # Convert the response hash to a Message object
        return unless response.is_a?(Hash)

        message_data = response.dig('choices', 0, 'message')
        return unless message_data

        Message.new(
          role: :assistant,
          content: message_data['content'],
          tool_calls: nil, # TODO: implement tool calls for red-candle
          input_tokens: response.dig('usage', 'prompt_tokens') || 0,
          output_tokens: response.dig('usage', 'completion_tokens') || 0,
          model_id: response['model'],
          raw: response
        )
      end
    end
  end
end

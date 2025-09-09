# frozen_string_literal: true

module RubyLLM
  module Providers
    class RedCandle
      # Capabilities module for the Red-Candle provider
      module Capabilities
        class << self
          def supported_capabilities
            %w[chat streaming function_calling structured_output vision]
          end

          def normalize_temperature(temperature, _model_id)
            # Red-Candle supports standard temperature range (0.0 to 2.0)
            return temperature if temperature.nil?

            temperature.clamp(0.0, 2.0)
          end

          def supports_streaming?
            true
          end

          def supports_tools?
            true
          end

          def supports_vision?
            true
          end

          def supports_structured_output?
            true
          end

          def max_tokens_limit(_model_id)
            # Most models support up to 4096 tokens, but this varies
            4096
          end
        end
      end
    end
  end
end

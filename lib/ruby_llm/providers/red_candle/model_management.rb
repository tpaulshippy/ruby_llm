# frozen_string_literal: true

module RubyLLM
  module Providers
    class RedCandle
      # Model loading and management methods for the Red-Candle provider
      module ModelManagement
        def get_or_create_model(model_id)
          # Extract the actual model ID string from the model object
          model_id_str = model_id.respond_to?(:id) ? model_id.id : model_id.to_s
          @model_instances[model_id_str] ||= load_model(model_id_str)
        end

        private

        def load_model(model_id)
          device = determine_best_device

          if model_id.include?('.gguf') || model_id.downcase.include?('gguf')
            # Handle GGUF models
            parts = model_id.split('@')
            repo_id = parts[0]
            gguf_file = parts[1] || guess_gguf_file(repo_id)

            Candle::LLM.from_pretrained(repo_id, device: device, gguf_file: gguf_file)
          else
            # Handle regular HuggingFace models
            Candle::LLM.from_pretrained(model_id, device: device)
          end
        rescue StandardError => e
          raise Error, "Failed to load Red-Candle model '#{model_id}': #{e.message}"
        end

        def determine_best_device
          Candle::Device.best
        rescue StandardError
          Candle::Device.cpu
        end

        def guess_gguf_file(repo_id)
          # Try common GGUF file patterns
          common_patterns = %w[Q4_K_M Q5_K_M Q8_0 q4_k_m q5_k_m q8_0]
          model_name = repo_id.split('/').last.downcase

          common_patterns.each do |pattern|
            candidate = "#{model_name}.#{pattern}.gguf"
            return candidate if File.exist?(candidate)
          end

          "#{model_name}.gguf"
        end
      end
    end
  end
end

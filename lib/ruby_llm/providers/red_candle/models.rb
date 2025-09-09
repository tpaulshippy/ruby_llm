# frozen_string_literal: true

module RubyLLM
  module Providers
    class RedCandle
      # Models discovery methods for the Red-Candle provider
      module Models
        def models_url
          'local://models'
        end

        def parse_list_models_response(_response, slug, capabilities)
          # For Red-Candle, we'll return a curated list of known working models
          # In a more complete implementation, this could scan the HuggingFace cache
          get_supported_models(slug, capabilities)
        end

        def list_models
          get_supported_models(slug, capabilities)
        end

        private

        def get_supported_models(slug, capabilities)
          [
            # Lightweight models good for testing
            build_model_info('microsoft/phi-2', slug, capabilities, 'phi', 'Small but capable model'),
            build_model_info('TinyLlama/TinyLlama-1.1B-Chat-v1.0', slug, capabilities, 'llama', 'Tiny Llama model'),

            # Popular GGUF models
            build_model_info('TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF@tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
                             slug, capabilities, 'llama', 'Quantized TinyLlama (Q4_K_M)'),
            build_model_info('TheBloke/Mistral-7B-Instruct-v0.2-GGUF@mistral-7b-instruct-v0.2.Q4_K_M.gguf',
                             slug, capabilities, 'mistral', 'Quantized Mistral 7B (Q4_K_M)'),

            # Full precision models (require more RAM)
            build_model_info('mistralai/Mistral-7B-Instruct-v0.1', slug, capabilities, 'mistral',
                             'Mistral 7B Instruct'),
            build_model_info('google/gemma-2b-it', slug, capabilities, 'gemma', 'Gemma 2B Instruct')
          ]
        end

        def build_model_info(model_id, provider_slug, capabilities, family, description)
          Model::Info.new(
            id: model_id,
            name: extract_model_name(model_id),
            provider: provider_slug,
            family: family,
            description: description,
            created_at: Time.now,
            modalities: {
              input: %w[text],
              output: %w[text]
            },
            capabilities: capabilities + ['local_inference'],
            pricing: {
              input: 0.0,
              output: 0.0,
              request: 0.0
            },
            metadata: {
              local: true,
              requires_gpu: family == 'mistral' && !model_id.include?('GGUF'),
              memory_usage: estimate_memory_usage(model_id, family),
              architecture: family
            }
          )
        end

        def extract_model_name(model_id)
          # Remove GGUF suffix and extract readable name
          name = model_id.split('@').first
          name.split('/').last.gsub(/[-_]/, ' ').gsub(/\b\w/, &:upcase)
        end

        def estimate_memory_usage(model_id, family)
          return estimate_gguf_memory(model_id) if model_id.include?('GGUF')

          estimate_full_precision_memory(model_id, family)
        end

        def estimate_gguf_memory(model_id)
          case model_id
          when /Q4_K_M/ then '~4GB'
          when /Q5_K_M/ then '~5GB'
          when /Q8_0/ then '~8GB'
          else '~3GB'
          end
        end

        def estimate_full_precision_memory(model_id, family)
          case family
          when 'phi' then '~6GB'
          when 'llama' then model_id.include?('TinyLlama') ? '~2GB' : '~14GB'
          when 'mistral' then '~14GB'
          when 'gemma' then model_id.include?('2b') ? '~4GB' : '~14GB'
          else '~8GB'
          end
        end
      end
    end
  end
end

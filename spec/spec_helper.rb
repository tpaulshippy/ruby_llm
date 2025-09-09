# frozen_string_literal: true

require 'dotenv/load'
require 'simplecov'
require 'simplecov-cobertura'
require 'codecov'
require 'vcr'
require 'bundler/setup'
require 'fileutils'
require 'ruby_llm'
require 'webmock/rspec'
require 'active_support'
require 'active_support/core_ext'
require_relative 'support/rspec_configuration'
require_relative 'support/rubyllm_configuration'
require_relative 'support/simplecov_configuration'
require_relative 'support/vcr_configuration'
require_relative 'support/models_to_test'
require_relative 'support/streaming_error_helpers'

# Setup red-candle provider for testing if available
# This must be done after RubyLLM is loaded and Provider class is available
begin
  require 'candle'
  if defined?(Candle::LLM) && RubyLLM::Provider.providers.key?(:red_candle)
    # Red-candle is already registered by the plugin system
    # Just add test models to the suite
    red_candle_test_models = [
      { provider: :red_candle, model: 'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF@tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf' }
    ]
    
    CHAT_MODELS.concat(red_candle_test_models)
  end
rescue LoadError
  # Red-candle not available, skip silently
end

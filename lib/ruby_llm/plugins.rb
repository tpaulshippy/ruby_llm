# frozen_string_literal: true

module RubyLLM
  # Plugin system for optional provider integrations
  module Plugins
    class << self
      def load_available_plugins
        load_red_candle if red_candle_available?
      end

      def red_candle_available?
        require 'candle'
        # Check if LLM class is available (red-candle specific)
        defined?(Candle::LLM) && Candle::LLM.respond_to?(:from_pretrained)
      rescue LoadError => e
        RubyLLM.logger.debug "Red-Candle not available: #{e.message}"
        false
      end

      private

      def load_red_candle
        require 'ruby_llm/providers/red_candle'
        Provider.register :red_candle, Providers::RedCandle
        RubyLLM.logger.info 'Red-Candle plugin loaded successfully'
      rescue LoadError => e
        RubyLLM.logger.warn "Failed to load Red-Candle plugin: #{e.message}"
      end
    end
  end
end

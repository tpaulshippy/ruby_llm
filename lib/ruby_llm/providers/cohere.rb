# frozen_string_literal: true

module RubyLLM
  module Providers
    # Cohere API integration. Handles Command models for chat completion
    # and Embed models for text embeddings.
    #
    # NOTE: While Cohere have an OpenAI-format compatible API, we have opted to support a native
    # Cohere API implementation so we have the optionality to support Cohere specific features across
    # chat (documents, citations, safety mode, etc.) and embeddings (input types, image embeddings, etc.)
    # while easily supporting other features like reranking and classification.
    #
    # See https://docs.cohere.com/docs/compatibility-api for more information.
    class Cohere < Provider
      include Cohere::Chat
      include Cohere::Embeddings
      include Cohere::Models
      include Cohere::Streaming
      include Cohere::Tools
      include Cohere::Media

      def api_base
        'https://api.cohere.ai'
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.cohere_api_key}",
          'Content-Type' => 'application/json'
        }
      end

      def capabilities
        Cohere::Capabilities
      end

      def slug
        'cohere'
      end

      def configuration_requirements
        %i[cohere_api_key]
      end

      def parse_error(response)
        return if response.body.empty?

        JSON.parse(response.response.body)['message']
      end
    end
  end
end

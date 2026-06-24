module Ai
  module Rag
    class EmbeddingService < ApplicationService
      def initialize(texts)
        @texts = Array(texts)
        super()
      end

      def call
        return [] if @texts.empty?
        adapter.embed(@texts)
      end

      private

      def adapter
        provider = Rails.configuration.ai.embedding_provider || "anthropic"
        "Ai::Rag::#{provider.camelize}EmbeddingAdapter".constantize.new
      end
    end
  end
end

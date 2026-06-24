module Ai
  module Rag
    class AnthropicEmbeddingAdapter < BaseEmbeddingAdapter
      ANTHROPIC_EMBEDDING_URL = "https://api.anthropic.com/v1/embeddings".freeze
      ANTHROPIC_VERSION = "2023-06-01".freeze

      def embed(texts)
        texts = Array(texts)
        return [] if texts.empty?

        texts.map do |text|
          response = HTTParty.post(
            ANTHROPIC_EMBEDDING_URL,
            headers: {
              "x-api-key" => ENV.fetch("ANTHROPIC_API_KEY"),
              "anthropic-version" => ANTHROPIC_VERSION,
              "content-type" => "application/json"
            },
            body: {
              model: "claude-3-haiku-20240307",
              input: text
            }.to_json
          )

          raise "Anthropic embedding error: #{response.code}" unless response.success?
          response.parsed_response.dig("embedding")
        end
      rescue HTTParty::Error => e
        raise "Anthropic embedding request failed: #{e.message}"
      end
    end
  end
end

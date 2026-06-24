module Ai
  class Provider < ApplicationService
    ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages".freeze
    ANTHROPIC_VERSION = "2023-06-01".freeze

    def initialize(prompt:, model: "claude-3-haiku-20240307", max_tokens: 1024)
      @prompt = prompt
      @model = model
      @max_tokens = max_tokens
      super()
    end

    def call
      response = HTTParty.post(
        ANTHROPIC_API_URL,
        headers: {
          "x-api-key" => ENV.fetch("ANTHROPIC_API_KEY"),
          "anthropic-version" => ANTHROPIC_VERSION,
          "content-type" => "application/json"
        },
        body: {
          model: @model,
          max_tokens: @max_tokens,
          messages: [{ role: "user", content: @prompt }]
        }.to_json
      )

      raise "Anthropic API error: #{response.code} - #{response.body}" unless response.success?

      response.parsed_response.dig("content", 0, "text")
    rescue HTTParty::Error => e
      raise "Anthropic API request failed: #{e.message}"
    end
  end
end

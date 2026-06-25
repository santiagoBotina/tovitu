module Ai
  class Provider < ApplicationService
    OPENAI_API_URL = "https://api.openai.com/v1/chat/completions".freeze

    def initialize(prompt:, system_prompt: nil, model: "gpt-4o-mini", max_tokens: 2048)
      @prompt = prompt
      @system_prompt = system_prompt
      @model = model
      @max_tokens = max_tokens
      super()
    end

    def call
      messages = []
      messages << { role: "system", content: @system_prompt } if @system_prompt
      messages << { role: "user", content: @prompt }

      body = {
        model: @model,
        max_tokens: @max_tokens,
        messages: messages,
        response_format: { type: "json_object" }
      }

      response = HTTParty.post(
        OPENAI_API_URL,
        headers: {
          "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
          "content-type" => "application/json"
        },
        body: body.to_json
      )

      unless response.success?
        error_body = response.parsed_response.dig("error", "message") || response.body
        raise Ai::ProviderError, "OpenAI API error: #{response.code} - #{error_body}"
      end

      response.parsed_response.dig("choices", 0, "message", "content")
    rescue HTTParty::Error => e
      raise Ai::ProviderError, "OpenAI API request failed: #{e.message}"
    end
  end
end

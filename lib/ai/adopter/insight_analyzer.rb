module Ai
  module Adopter
    # Generates the Adopter Insight Profile (cached per adopter) from the
    # evidence base produced by SignalCollector.
    class InsightAnalyzer < ApplicationService
      CONFIDENCE_LEVELS = %w[high medium low].freeze
      SIGNAL_KINDS = %w[positive neutral attention].freeze

      def initialize(adopter:, signals:)
        @adopter = adopter
        @signals = signals
        super()
      end

      def call
        prompt = Ai::PromptBuilder.call(
          prompt_name: "adopter_insight",
          variables: prompt_variables
        )

        response = Ai::Provider.call(prompt: prompt, system_prompt: system_prompt)
        parsed = JSON.parse(response)
        return Result.failure("Unexpected AI response shape: expected a JSON object") unless parsed.is_a?(Hash)

        Result.success(normalize(parsed))
      rescue Ai::ProviderError => e
        Result.failure(e.message)
      rescue JSON::ParserError => e
        Result.failure("Failed to parse AI response: #{e.message}")
      end

      private

      attr_reader :adopter, :signals

      def system_prompt
        YAML.load_file(Rails.root.join("config/prompts/adopter_insight.yml"))["system_prompt"]
      end

      def prompt_variables
        {
          adopter_evidence: signals.except(:fingerprint).to_json,
          archetype_taxonomy: Archetype.prompt_taxonomy,
          provenance_sources: provenance_sources.join(", ")
        }
      end

      def provenance_sources
        sources = []
        sources << "onboarding answers" if signals.dig(:profile, :personality).present? || signals.dig(:profile, :activity_level).present?
        sources << "#{signals[:behavior][:saved_pets_count]} saved pets" if signals[:behavior][:saved_pets_count].to_i.positive?
        sources << "#{signals[:behavior][:requests_count]} request(s)" if signals[:behavior][:requests_count].to_i.positive?
        sources << "response time" if signals[:behavior][:avg_response_hours].present?
        sources.empty? ? [ "onboarding answers" ] : sources
      end

      def normalize(data)
        {
          archetype: normalize_archetype(data["archetype"]),
          self_reported_personality: signals.dig(:profile, :personality),
          archetype_diverges: normalize_boolean(data["archetype_diverges"]),
          commitment_signals: normalize_commitment_signals(data["commitment_signals"]),
          confidence: normalize_confidence(data["confidence"]),
          provenance: {
            sources: provenance_sources,
            based_on: based_on(data["based_on"]),
            activity_up_to: Date.current.iso8601
          }
        }
      end

      def normalize_archetype(value)
        return nil unless value.is_a?(String)
        return nil unless Archetype.valid_key?(value)

        value
      end

      # Accepts booleans and common truthy string spellings so a sloppy model
      # response ("true", "True", "yes", 1) is not silently treated as false.
      def normalize_boolean(value)
        [ true, 1, "true", "True", "TRUE", "yes", "Yes", "YES" ].include?(value)
      end

      def normalize_commitment_signals(value)
        Array(value).filter_map do |item|
          next unless item.is_a?(Hash)

          observation = item["observation"]
          next unless observation.is_a?(String)

          observation = Ai::Sanitizer.truncated(observation, limit: 300)
          next if observation.blank?

          label = item["label"].is_a?(String) ? Ai::Sanitizer.text(item["label"]) : nil
          {
            label: label.presence || "observation",
            observation: observation,
            kind: SIGNAL_KINDS.include?(item["kind"]) ? item["kind"] : "neutral"
          }
        end.first(6)
      end

      def normalize_confidence(value)
        CONFIDENCE_LEVELS.include?(value) ? value : "medium"
      end

      def based_on(value)
        return provenance_sources.join(", ") unless value.is_a?(String)

        Ai::Sanitizer.truncated(value, limit: 300).presence || provenance_sources.join(", ")
      end
    end
  end
end

module Ai
  module Adopter
    # Generates the Pet-Fit Summary (per request): how this adopter matches
    # THIS specific pet, with evidence-backed fit indicators, a short summary,
    # and verification questions for the reviewer.
    class PetFitAnalyzer < ApplicationService
      CONFIDENCE_LEVELS = %w[high medium low].freeze
      STATUSES = %w[strong_fit possible_mismatch unknown].freeze
      DIMENSIONS = %w[energy time experience home_space household].freeze

      def initialize(request:, signals:, insight:)
        @request = request
        @signals = signals
        @insight = insight
        super()
      end

      def call
        prompt = Ai::PromptBuilder.call(
          prompt_name: "pet_fit_summary",
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

      attr_reader :request, :signals, :insight

      def system_prompt
        YAML.load_file(Rails.root.join("config/prompts/pet_fit_summary.yml"))["system_prompt"]
      end

      def prompt_variables
        {
          pet_profile: pet_profile.to_json,
          adopter_profile: adopter_profile.to_json,
          request_answers: request_answers.to_json
        }
      end

      def pet_profile
        pet = request.pet
        {
          name: pet.name,
          species: pet.species,
          breed: pet.breed.presence || "Mixed",
          age_category: pet.age_category,
          size: pet.size,
          sex: pet.sex,
          personality_traits: Array(pet.personality_traits).first(8),
          good_with_children: pet.good_with_children?,
          good_with_dogs: pet.good_with_dogs?,
          good_with_cats: pet.good_with_cats?,
          special_needs: pet.special_needs?,
          description: Ai::Sanitizer.truncated(pet.description, limit: 400).presence || "Not provided.",
          requirements: Ai::Sanitizer.truncated(Array(pet.requirements).join(", "), limit: 300)
        }
      end

      def adopter_profile
        {
          insight: insight,
          evidence: signals.except(:fingerprint)
        }
      end

      def request_answers
        answers = request.additional_answers.to_h.with_indifferent_access
        {
          interest_reason: Ai::Sanitizer.truncated(answers[:interest_reason], limit: 500),
          home_description: Ai::Sanitizer.truncated(answers[:home_description], limit: 500),
          current_pets_details: Ai::Sanitizer.truncated(answers[:current_pets_details], limit: 500),
          something_else: Ai::Sanitizer.truncated(answers[:something_else], limit: 500)
        }
      end

      def normalize(data)
        {
          fit_indicators: normalize_fit_indicators(data["fit_indicators"]),
          summary: normalize_summary(data["summary"]),
          verification_questions: normalize_questions(data["verification_questions"]),
          confidence: normalize_confidence(data["confidence"])
        }
      end

      def normalize_fit_indicators(value)
        DIMENSIONS.each_with_object({}) do |dimension, hash|
          item = value.is_a?(Hash) ? value[dimension] : nil
          status = normalize_status(item.is_a?(Hash) ? item["status"] : nil)
          evidence =
            if item.is_a?(Hash) && item["evidence"].is_a?(String)
              Ai::Sanitizer.truncated(item["evidence"], limit: 200)
            end

          hash[dimension] = {
            status: status,
            evidence: evidence || ""
          }
        end
      end

      def normalize_status(value)
        STATUSES.include?(value) ? value : "unknown"
      end

      def normalize_summary(value)
        return "" unless value.is_a?(String)

        Ai::Sanitizer.truncated(value, limit: 600).presence || ""
      end

      def normalize_questions(value)
        Array(value).filter_map do |q|
          next unless q.is_a?(String)

          Ai::Sanitizer.truncated(q, limit: 300)
        end.first(3)
      end

      def normalize_confidence(value)
        CONFIDENCE_LEVELS.include?(value) ? value : "medium"
      end
    end
  end
end

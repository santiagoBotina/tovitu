module Ai
  # Translates shelter natural-language adoption policies into proposed
  # structured rules from the bounded vocabulary (REQ-49-4). Vendor-agnostic:
  # builds a prompt, calls Ai::Provider, validates/normalizes the output, and
  # never fabricates — statements that cannot be mapped come back as
  # not_evaluated. Translation happens at policy-save time, never per request.
  class TranslatePolicy < ApplicationService
    def initialize(policies:)
      @policies = Array(policies).map(&:to_s).map(&:strip).reject(&:blank?)
    end

    def call
      return Result.success([]) if @policies.empty?

      prompt = Ai::PromptBuilder.call(
        prompt_name: "policy_translation",
        variables: {
          vocabulary: Adoptions::Evaluation::RuleCatalog.prompt_vocabulary,
          policies: @policies.map { |p| "- #{p}" }.join("\n")
        }
      )

      response = Ai::Provider.call(prompt: prompt, system_prompt: system_prompt)
      parsed = JSON.parse(response)
      items = extract_translations(parsed)
      return Result.failure("Unexpected AI response shape: expected a JSON object with a 'translations' array") if items.nil?

      Result.success(normalize(items))
    rescue Ai::ProviderError => e
      Result.failure(e.message)
    rescue JSON::ParserError => e
      Result.failure("Failed to parse AI response: #{e.message}")
    end

    private

    # The provider is configured for JSON-object responses, so the model wraps
    # the array in an object ({ "translations": [...] }). Accept a bare array
    # defensively in case a provider variant returns one directly.
    def extract_translations(parsed)
      case parsed
      when Array then parsed
      when Hash then parsed["translations"] if parsed["translations"].is_a?(Array)
      end
    end

    def system_prompt
      YAML.load_file(Rails.root.join("config/prompts/policy_translation.yml"))["system_prompt"]
    end

    def normalize(items)
      items.filter_map do |item|
        next unless item.is_a?(Hash)

        statement = item["statement"].to_s.strip
        next if statement.blank?

        rules = normalize_rules(item["rules"])
        if item["status"] == "translated" && rules.any?
          { statement: statement, status: "translated", rules: rules, reason: nil }
        else
          { statement: statement, status: "not_evaluated", rules: [],
            reason: normalize_reason(item["reason"]) }
        end
      end
    end

    def normalize_reason(value)
      ShelterEvaluationPolicy::REASONS.include?(value.to_s) ? value.to_s : "unsupported_data"
    end

    def normalize_rules(value)
      Array(value).filter_map do |rule|
        next unless rule.is_a?(Hash)
        next unless Adoptions::Evaluation::RuleCatalog.valid_key?(rule["rule_type"])

        {
          rule_type: rule["rule_type"],
          params: Adoptions::Evaluation::RuleCatalog.normalize_params(rule["rule_type"], rule["params"]),
          severity: %w[red yellow].include?(rule["severity"]) ? rule["severity"] : "yellow"
        }
      end
    end
  end
end

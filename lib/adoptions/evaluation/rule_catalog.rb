module Adoptions
  module Evaluation
    # Bounded, evaluable rule vocabulary (REQ-49-5). Every rule type maps to a
    # real stored signal; the translation service validates/normalizes AI output
    # against this catalog, and policies that reference anything outside it are
    # honestly marked "not auto-evaluated".
    class RuleCatalog
      PET_EXPERIENCE_LEVELS = %w[first_time some_experience years_of_experience very_experienced].freeze
      DAILY_TIME_LEVELS = %w[less_than_1h 1_to_2h 2_to_4h more_than_4h].freeze

      CATALOG = {
        "account_age_min" => {
          params: { "days" => :integer },
          prompt_description: "Requires the adopter's account to be at least a given number of days old (param: days)."
        },
        "email_verified" => {
          params: {},
          prompt_description: "Requires the adopter's email to be verified."
        },
        "adopter_age_min" => {
          params: { "years" => :integer },
          prompt_description: "Requires the adopter to be at least a given age in years (param: years)."
        },
        "home_fenced_yard_required" => {
          params: {},
          prompt_description: "Requires the adopter's home to have a fenced yard."
        },
        "other_pets_allowed" => {
          params: {},
          prompt_description: "Requires the adopter's home to have no other pets."
        },
        "profile_completeness_min" => {
          params: { "percent" => :integer },
          prompt_description: "Requires the adopter's profile to be at least a given percent complete (param: percent)."
        },
        "pet_experience_min" => {
          params: { "level" => :pet_experience_level },
          prompt_description: "Requires at least a given pet experience level (param: level one of first_time, some_experience, years_of_experience, very_experienced)."
        },
        "daily_time_available_min" => {
          params: { "level" => :daily_time_level },
          prompt_description: "Requires at least a given daily time available level (param: level one of less_than_1h, 1_to_2h, 2_to_4h, more_than_4h)."
        },
        "adoption_priority_present" => {
          params: {},
          prompt_description: "Requires the adopter to have stated their adoption motivation."
        },
        "additional_answers_present" => {
          params: {},
          prompt_description: "Requires the adopter to have answered the request questions."
        },
        "no_prior_decline_same_pet" => {
          params: {},
          prompt_description: "Excludes adopters with a prior declined or withdrawn request for the same pet."
        }
      }.freeze

      def self.valid_key?(rule_type)
        CATALOG.key?(rule_type.to_s)
      end

      def self.label_key(rule_type)
        "adoptions.evaluation.rules.#{rule_type}.label"
      end

      def self.description_key(rule_type)
        "adoptions.evaluation.rules.#{rule_type}.description"
      end

      def self.param_schema(rule_type)
        CATALOG.dig(rule_type.to_s, :params) || {}
      end

      # Coerce AI-supplied params into valid values per the rule's schema.
      # Invalid params are dropped; a rule whose params end up invalid still
      # evaluates with its defaults where applicable.
      def self.normalize_params(rule_type, params)
        schema = param_schema(rule_type)
        return {} if schema.empty?

        source = params.respond_to?(:to_unsafe_h) ? params.to_h : (params || {})
        source.each_with_object({}) do |(key, value), out|
          next unless schema.key?(key.to_s)

          normalized = normalize_value(schema[key.to_s], value)
          out[key.to_s] = normalized if normalized
        end
      end

      def self.normalize_value(type, value)
        case type
        when :integer
          int = Integer(value) rescue nil
          int if int && int.positive?
        when :pet_experience_level
          PET_EXPERIENCE_LEVELS.include?(value.to_s) ? value.to_s : nil
        when :daily_time_level
          DAILY_TIME_LEVELS.include?(value.to_s) ? value.to_s : nil
        end
      end

      def self.prompt_vocabulary
        CATALOG.map { |type, meta| "- #{type}: #{meta[:prompt_description]}" }.join("\n")
      end
    end
  end
end

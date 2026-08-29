module Ai
  # Converts a natural-language search phrase into a structured intent hash
  # used by Pets::NaturalSearch to rank adoptable pets.
  #
  # Provider-agnostic: delegates to Ai::Provider and Ai::PromptBuilder. The
  # prompt template lives in config/prompts/search_intent.yml.
  #
  # On success, result.data is a Hash with STRING keys:
  #   "species"          => Array of species keys from the allowed set
  #   "size"             => Array from %w[small medium large giant]
  #   "age_category"     => Array from %w[baby young adult senior]
  #   "sex"              => Array from %w[male female]
  #   "temperament"      => Array of free-text temperament keywords
  #   "living_situation" => Array of free-text living-situation hints
  #   "energy_level"     => Array of free-text energy hints
  #   "keywords"         => Array of significant full-phrase concepts
  #   "understood"       => Array of localized short human labels
  #   "valid"            => true/false
  class ExtractSearchIntent < ApplicationService
    SUPPORTED_LOCALES = %w[en es].freeze
    LANGUAGE_NAMES = { "en" => "English", "es" => "Spanish" }.freeze
    MAX_PHRASE_LENGTH = 300

    def initialize(phrase:, locale: nil)
      @phrase = phrase
      @locale = normalize_locale(locale)
      super()
    end

    def call
      clean_phrase = Ai::Sanitizer.truncated(phrase, limit: MAX_PHRASE_LENGTH)
      return Result.success(empty_intent) if clean_phrase.blank?

      prompt_vars = { language: LANGUAGE_NAMES.fetch(locale, "English"), phrase: clean_phrase }
      prompt = Ai::PromptBuilder.call(prompt_name: "search_intent", variables: prompt_vars)

      prompt_config = YAML.load_file(Rails.root.join("config/prompts/search_intent.yml"))
      system_prompt = Ai::PromptBuilder.interpolate(prompt_config["system_prompt"], prompt_vars)

      response = Ai::Provider.call(prompt: prompt, system_prompt: system_prompt)
      parsed = JSON.parse(response.to_s)
      Result.success(normalize_data(parsed))
    rescue Ai::ProviderError => e
      Result.failure(e.message)
    rescue JSON::ParserError => e
      Result.failure("Failed to parse AI response: #{e.message}")
    end

    private

    attr_reader :phrase, :locale

    def normalize_locale(value)
      candidate = value.presence || I18n.locale.to_s
      SUPPORTED_LOCALES.include?(candidate) ? candidate : I18n.default_locale.to_s
    end

    def empty_intent
      {
        "species" => [],
        "size" => [],
        "age_category" => [],
        "sex" => [],
        "temperament" => [],
        "living_situation" => [],
        "energy_level" => [],
        "keywords" => [],
        "understood" => [],
        "valid" => false
      }
    end

    def normalize_data(raw)
      data = raw.is_a?(Hash) ? raw : {}
      species         = normalize_enum(data["species"], Pet::SPECIES)
      size            = normalize_enum(data["size"], Pet::SIZES)
      age_category    = normalize_enum(data["age_category"], Pet::AGE_CATEGORIES)
      sex             = normalize_enum(data["sex"], %w[male female])
      temperament     = normalize_strings(data["temperament"])
      living_situation = normalize_strings(data["living_situation"])
      energy_level    = normalize_strings(data["energy_level"])
      keywords        = normalize_strings(data["keywords"])

      {
        "species" => species,
        "size" => size,
        "age_category" => age_category,
        "sex" => sex,
        "temperament" => temperament,
        "living_situation" => living_situation,
        "energy_level" => energy_level,
        "keywords" => keywords,
        "understood" => understood_labels(species:, size:, age_category:, sex:,
                                          temperament:, living_situation:, energy_level:),
        "valid" => valid?(data)
      }
    end

    # Builds the "what Tovitu understood" chips deterministically from the
    # structured fields instead of trusting the model's free-text labels, so
    # species/size/age/sex are always rendered in the user's active locale even
    # if the provider ignores the language instruction. Free-text temperament /
    # living-situation / energy tokens are kept as the model returned them.
    def understood_labels(species:, size:, age_category:, sex:, temperament:, living_situation:, energy_level:)
      I18n.with_locale(locale) do
        labels = []
        labels.concat(species.map { |s| I18n.t("pets.species.#{s}") })
        labels.concat(age_category.map { |a| I18n.t("pets.age_categories.#{a}") })
        labels.concat(size.map { |s| I18n.t("pets.sizes.#{s}") })
        labels.concat(sex.map { |x| I18n.t("pets.sex.#{x}") })
        labels.concat(temperament)
        labels.concat(living_situation)
        labels.concat(energy_level)
        labels
      end
    end

    def normalize_enum(value, allowed)
      Array(value).map(&:to_s).select { |v| allowed.include?(v) }.uniq
    end

    def normalize_strings(value)
      Array(value).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    end

    def valid?(data)
      return false if data["valid"].to_s == "false"

      %w[species size age_category sex temperament living_situation energy_level keywords]
        .any? { |key| Array(data[key]).any? }
    end
  end
end

module Ai
  class GenerateLifePreview < ApplicationService
    SUPPORTED_LOCALES = %w[en es].freeze
    LANGUAGE_NAMES = { "en" => "English", "es" => "Spanish" }.freeze

    def initialize(pet:, personality_spec: nil, adopter_tips: nil, locale: nil)
      @pet = pet
      @personality_spec = personality_spec
      @adopter_tips = adopter_tips
      @locale = normalize_locale(locale)
      super()
    end

    def call
      prompt_vars = prompt_variables
      prompt = Ai::PromptBuilder.call(
        prompt_name: "life_preview",
        variables: prompt_vars
      )

      prompt_config = YAML.load_file(Rails.root.join("config/prompts/life_preview.yml"))
      system_prompt = Ai::PromptBuilder.interpolate(prompt_config["system_prompt"], prompt_vars)

      response = Ai::Provider.call(
        prompt: prompt,
        system_prompt: system_prompt
      )

      parsed = parse_response(response)
      parsed["locale"] = locale
      Result.success(parsed)
    rescue Ai::ProviderError => e
      Result.failure(e.message)
    rescue JSON::ParserError => e
      Result.failure("Failed to parse AI response: #{e.message}")
    end

    private

    attr_reader :pet, :personality_spec, :adopter_tips, :locale

    def normalize_locale(value)
      candidate = value.presence || I18n.locale.to_s
      SUPPORTED_LOCALES.include?(candidate) ? candidate : I18n.default_locale.to_s
    end

    def prompt_variables
      presenter = PetPresenter.new(pet)
      {
        pet_name: pet.name,
        species: pet.species,
        breed: pet.breed.presence || "Mixed",
        age: presenter.age_display,
        size: pet.size.presence || "Unknown",
        description: pet.description.presence || "No description provided.",
        personality_traits: presenter.personality_traits_list.join(", "),
        medical_notes: pet.medical_notes.presence || "None noted.",
        requirements: presenter.requirements_list.join(", "),
        good_with_children: pet.good_with_children? ? "Yes" : "No",
        good_with_dogs: pet.good_with_dogs? ? "Yes" : "No",
        good_with_cats: pet.good_with_cats? ? "Yes" : "No",
        spayed_neutered: pet.spayed_neutered? ? "Yes" : "No",
        vaccinated: pet.vaccinated? ? "Yes" : "No",
        special_needs: pet.special_needs? ? "Yes" : "No",
        personality_spec: personality_spec.presence || "Not provided by shelter.",
        adopter_tips: adopter_tips.presence || "Not provided by shelter.",
        language: LANGUAGE_NAMES.fetch(locale, "English")
      }
    end

    def parse_response(response)
      data = JSON.parse(response)
      normalize_structure(data)
      data
    end

    def normalize_structure(data)
      data["plan"] = normalize_plan(data["plan"]) if data["plan"]
      data["itinerary"] = normalize_itinerary(data["itinerary"]) if data["itinerary"]
      data["tips"] = normalize_tips(data["tips"]) if data["tips"]
    end

    def normalize_plan(plan)
      case plan
      when Array
        plan.map { |w| w.is_a?(Hash) ? { "week" => w["week"].to_s, "items" => Array(w["items"]) } : w }
      when Hash
        plan.map { |key, val| { "week" => key.to_s, "items" => Array(val) } }
      else
        []
      end
    end

    def normalize_itinerary(itinerary)
      expected = %w[daily_routine feeding_guide exercise_needs grooming vet_schedule]
      expected.each_with_object({}) do |key, hash|
        val = itinerary[key]
        hash[key] = val.is_a?(Hash) ? val.deep_stringify_keys : val.to_s
      end
    end

    def normalize_tips(tips)
      case tips
      when Hash
        tips.transform_values { |v| Array(v) }
      when Array
        tips.each_with_object({}) { |item, hash| hash[item.to_s] = [] }
      else
        {}
      end
    end
  end
end

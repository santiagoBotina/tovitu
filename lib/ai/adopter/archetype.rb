module Ai
  module Adopter
    # Adopter archetype taxonomy.
    #
    # Stable, locale-neutral keys are the single source of truth. The English
    # meaning here is what the model consumes inside prompts; the user-facing
    # label/description are translated via config/locales under
    # `ai.adopter_insight.archetypes.<key>.*`.
    class Archetype
      TAXONOMY = {
        active_outdoors_partner: {
          meaning: "A physically active person who spends significant time outside, hiking, running, or walking. A good match for high-energy, adventure-loving pets."
        },
        homebody_companion: {
          meaning: "A calm, home-centered person who wants a relaxed companion for quiet evenings. Best for low-energy, snuggly pets."
        },
        first_time_parent: {
          meaning: "New to pet care. Enthusiastic and willing to learn, but may need guidance, patience, and simple routines."
        },
        experienced_guardian: {
          meaning: "Has years of pet experience and handles confident, complex, or special-needs pets with ease."
        },
        family_builder: {
          meaning: "Adopting as part of a family (children and/or other pets) and prioritizing a pet that fits a busy, lively household."
        },
        routine_keeper: {
          meaning: "Lives by a predictable schedule with dependable time for feeding, walks, and care. A great match for pets that thrive on routine."
        },
        spontaneous_spirit: {
          meaning: "Flexible and spontaneous; comfortable adapting plans around a pet. Matches pets that are flexible too, though consistency may need attention."
        },
        social_house: {
          meaning: "Their home is often full of people and visitors. A great match for outgoing, people-loving pets; stressful for shy ones."
        }
      }.freeze

      KEYS = TAXONOMY.keys.freeze

      DEFAULT_LABEL_KEY = "ai.adopter_insight.archetypes.unknown"

      def self.prompt_taxonomy
        TAXONOMY.map { |key, info| "- #{key}: #{info[:meaning]}" }.join("\n")
      end

      def self.valid_key?(key)
        key.is_a?(String) && key.present? && KEYS.include?(key.to_sym)
      end

      def self.label_key(key)
        return DEFAULT_LABEL_KEY if key.blank?
        "ai.adopter_insight.archetypes.#{key}"
      end
    end
  end
end

module Onboarding
  module Adopter
    class QuestionsData
      DEFINITIONS = [
        {
          number: 1,
          key: "weekend_activity",
          type: "multi_select",
          options: %w[relaxing_at_home going_for_walks outdoor_adventures
                       spending_time_with_family exercising_or_sports
                       visiting_friends exploring_new_places]
        },
        {
          number: 2,
          key: "activity_level",
          type: "single_select",
          options: %w[very_calm mostly_calm balanced active very_active]
        },
        {
          number: 3,
          key: "ideal_companion",
          type: "single_select",
          options: %w[calm_friend playful_companion affectionate_pet
                       independent_pet social_pet]
        },
        {
          number: 4,
          key: "pet_experience",
          type: "single_select",
          options: %w[first_time some_experience years_of_experience very_experienced]
        },
        {
          number: 5,
          key: "adoption_goals",
          type: "multi_select",
          options: %w[daily_companion more_activity emotional_support
                       family_pet friend_for_pet meaningful_help]
        },
        {
          number: 6,
          key: "daily_time_available",
          type: "single_select",
          options: %w[less_than_1h 1_to_2h 2_to_4h more_than_4h]
        },
        {
          number: 7,
          key: "personality",
          type: "single_select",
          options: %w[calm_thoughtful friendly_social adventurous_energetic
                       organized_routine flexible_spontaneous]
        },
        {
          number: 8,
          key: "adoption_priority",
          type: "text",
          options: [],
          max_length: 200
        }
      ].freeze

      def self.all
        DEFINITIONS
      end

      def self.find(number)
        DEFINITIONS.find { |q| q[:number] == number.to_i }
      end

      def self.count
        DEFINITIONS.size
      end
    end
  end
end

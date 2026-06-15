module Onboarding
  module Shelter
    class QuestionsData
      DEFINITIONS = [
        {
          number: 1,
          key: "organization_type",
          type: "single_select",
          options: %w[small_rescue independent_shelter large_shelter
                       ngo_foundation foster_based]
        },
        {
          number: 2,
          key: "pet_count_range",
          type: "single_select",
          options: %w[under_20 20_to_50 50_to_100 over_100]
        },
        {
          number: 3,
          key: "adoption_involvement",
          type: "single_select",
          options: %w[basic_screening interviews extensive_matching long_term_support]
        },
        {
          number: 4,
          key: "approval_priorities",
          type: "multi_select",
          options: %w[stable_home pet_experience available_time
                       financial_preparedness family_compatibility long_term_commitment]
        },
        {
          number: 5,
          key: "communication_channels",
          type: "multi_select",
          options: %w[whatsapp email phone_calls in_person social_media]
        },
        {
          number: 6,
          key: "biggest_challenges",
          type: "multi_select",
          options: %w[finding_qualified_adopters managing_applications
                       following_up communicating_with_adopters
                       managing_pet_info tracking_outcomes]
        },
        {
          number: 7,
          key: "approval_philosophy",
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

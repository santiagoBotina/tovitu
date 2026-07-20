module Onboarding
  module Shelter
    class Personality < ApplicationService
      PERSONALITIES = {
        guardian: {
          key: :guardian,
          name: "Compassionate Guardian",
          icon: "\u{1F6E1}\u{FE0F}",
          description_key: "onboarding.shelter.personality.guardian.description"
        },
        heart_led: {
          key: :heart_led,
          name: "Heart-Led Rescuer",
          icon: "\u{2764}\u{FE0F}",
          description_key: "onboarding.shelter.personality.heart_led.description"
        },
        process_pro: {
          key: :process_pro,
          name: "Process Pro",
          icon: "\u{1F4CB}",
          description_key: "onboarding.shelter.personality.process_pro.description"
        },
        community_builder: {
          key: :community_builder,
          name: "Community Builder",
          icon: "\u{1F91D}",
          description_key: "onboarding.shelter.personality.community_builder.description"
        },
        growth_partner: {
          key: :growth_partner,
          name: "Growth Partner",
          icon: "\u{1F331}",
          description_key: "onboarding.shelter.personality.growth_partner.description"
        }
      }.freeze

      MATCH_RULES = {
        guardian: {
          adoption_involvement: "extensive_matching",
          approval_priorities_include: "long_term_commitment"
        },
        heart_led: {
          organization_type: %w[small_rescue],
          adoption_involvement: "basic_screening"
        },
        process_pro: {
          organization_type: %w[large_shelter],
          biggest_challenges_include: "managing_applications"
        },
        community_builder: {
          organization_type: %w[foster_based],
          communication_channels_include: "whatsapp"
        },
        growth_partner: {
          organization_type: %w[ngo_foundation],
          adoption_involvement: "long_term_support"
        }
      }.freeze

      DEFAULT_PERSONALITY = :guardian

      def initialize(profile)
        @profile = profile
      end

      def call
        matched = PERSONALITIES.keys.find { |key| matches?(key) }
        result_key = matched || DEFAULT_PERSONALITY
        PERSONALITIES[result_key].merge(
          description: I18n.t(PERSONALITIES[result_key][:description_key])
        )
      end

      private

      def matches?(key)
        rules = MATCH_RULES[key]
        return false unless rules

        rules.all? do |field, expected|
          value = @profile&.send(field)

          case expected
          when Array
            Array(value).any? { |v| expected.include?(v) }
          when String
            if field.to_s.end_with?("_include")
              actual_field = field.to_s.sub("_include", "")
              actual_value = @profile&.send(actual_field)
              Array(actual_value).include?(expected)
            else
              value.to_s == expected
            end
          else
            false
          end
        end
      end
    end
  end
end

require "rails_helper"

RSpec.describe Onboarding::Shelter::Personality do
  def profile_with(attrs)
    build(:shelter_profile, attrs)
  end

  describe ".call" do
    it "matches Heart-Led Rescuer for a small rescue with basic screening" do
      result = described_class.call(
        profile_with(organization_type: "small_rescue", adoption_involvement: "basic_screening")
      )
      expect(result[:name]).to eq("Heart-Led Rescuer")
    end

    it "matches Process Pro for a large shelter with application management challenges" do
      result = described_class.call(
        profile_with(organization_type: "large_shelter", biggest_challenges: [ "managing_applications" ])
      )
      expect(result[:name]).to eq("Process Pro")
    end

    it "matches Community Builder for foster-based shelters using WhatsApp" do
      result = described_class.call(
        profile_with(organization_type: "foster_based", communication_channels: [ "whatsapp" ])
      )
      expect(result[:name]).to eq("Community Builder")
    end

    it "matches Growth Partner for an NGO foundation with long-term support" do
      result = described_class.call(
        profile_with(organization_type: "ngo_foundation", adoption_involvement: "long_term_support")
      )
      expect(result[:name]).to eq("Growth Partner")
    end

    it "does not crash when an _include rule references a nil array" do
      # The guardian rule reads approval_priorities_include; a nil array must
      # be treated as "no match" rather than raising NoMethodError.
      result = described_class.call(profile_with(organization_type: "large_shelter"))
      expect(result[:name]).to eq("Compassionate Guardian")
    end

    it "falls back to the default personality when nothing matches" do
      result = described_class.call(profile_with(organization_type: "independent_shelter", adoption_involvement: "none"))
      expect(result[:name]).to eq("Compassionate Guardian")
    end

    it "returns a localized description" do
      result = described_class.call(
        profile_with(organization_type: "small_rescue", adoption_involvement: "basic_screening")
      )
      expect(result[:description]).to eq(I18n.t("onboarding.shelter.personality.heart_led.description"))
    end
  end
end

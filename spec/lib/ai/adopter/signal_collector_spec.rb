require "rails_helper"

RSpec.describe Ai::Adopter::SignalCollector do
  subject(:signals) { described_class.call(adopter: adopter) }

  let(:adopter) { create(:user, :verified, :onboarding_completed) }

  describe "profile signals" do
    let!(:profile) do
      create(:individual_profile,
        user: adopter,
        weekend_activity: %w[outdoor_adventures going_for_walks],
        activity_level: "active",
        ideal_companion: "playful_companion",
        pet_experience: "some_experience",
        adoption_goals: %w[daily_companion more_activity],
        daily_time_available: "2_to_4h",
        personality: "adventurous_energetic",
        adoption_priority: "I want a dog to hike with.")
    end

    it "includes the onboarding answers" do
      expect(signals[:profile]).to include(
        activity_level: "active",
        ideal_companion: "playful_companion",
        pet_experience: "some_experience",
        daily_time_available: "2_to_4h",
        personality: "adventurous_energetic",
        weekend_activity: %w[outdoor_adventures going_for_walks],
        adoption_goals: %w[daily_companion more_activity]
      )
    end

    it "keeps the self-reported personality for the self-report vs behavior comparison" do
      expect(signals[:profile][:personality]).to eq("adventurous_energetic")
    end
  end

  describe "behavior signals" do
    let(:pet) { create(:pet, species: "dog", personality_traits: [ "Energetic", "Friendly" ]) }
    let(:other_pet) { create(:pet, species: "cat") }

    it "reports saved pets without PII" do
      create(:saved_pet, user: adopter, pet: pet)
      create(:saved_pet, user: adopter, pet: other_pet)

      expect(signals[:behavior][:saved_pets_count]).to eq(2)
      expect(signals[:behavior][:saved_pets].first).to include(species: "dog", size: pet.size)
    end

    it "reports request history" do
      create(:adoption_request, adopter: adopter, pet: pet)
      create(:adoption_request, adopter: adopter, pet: other_pet, status: :declined)

      expect(signals[:behavior][:requests_count]).to eq(2)
      expect(signals[:behavior][:active_requests_count]).to eq(1)
      expect(signals[:behavior][:unique_species_applied_to]).to include("dog", "cat")
    end

    it "derives follow-through from terminal request statuses" do
      create(:adoption_request, adopter: adopter, pet: pet, status: :accepted)
      create(:adoption_request, adopter: adopter, pet: other_pet, status: :withdrawn, withdrawn_at: Time.current)

      expect(signals[:behavior][:followed_through_ratio]).to eq(0.5)
    end

    it "excludes declined requests from follow-through (rejection is the shelter's decision)" do
      create(:adoption_request, adopter: adopter, pet: pet, status: :declined)
      create(:adoption_request, adopter: adopter, pet: other_pet, status: :declined)

      expect(signals[:behavior][:followed_through_ratio]).to be_nil
    end

    it "returns nil follow-through when there are no completed requests" do
      create(:adoption_request, adopter: adopter, pet: pet, status: :pending)

      expect(signals[:behavior][:followed_through_ratio]).to be_nil
    end

    it "derives response latency from withdrawal timestamps" do
      create(:adoption_request, adopter: adopter, pet: pet, status: :withdrawn,
             created_at: 3.hours.ago, withdrawn_at: 1.hour.ago)

      expect(signals[:behavior][:avg_response_hours]).to eq(2.0)
    end
  end

  describe "PII stripping" do
    it "never includes the adopter's name, email, or phone in the payload" do
      payload = signals
      serialized = payload.to_json

      expect(serialized).not_to include(adopter.name)
      expect(serialized).not_to include(adopter.email)
      expect(serialized).not_to include("555-1234")
    end

    it "redacts emails and phones inside free-text answers" do
      create(:individual_profile,
        user: adopter,
        adoption_priority: "Reach me at janedoe@example.com or 555-123-4567 to arrange a visit.")

      expect(signals[:profile][:adoption_priority]).not_to include("janedoe@example.com")
      expect(signals[:profile][:adoption_priority]).not_to include("555-123-4567")
    end

    it "preserves date-like strings that are not phone numbers" do
      create(:individual_profile,
        user: adopter,
        adoption_priority: "Available to adopt from 2024-08-06 onward.")

      expect(signals[:profile][:adoption_priority]).to include("2024-08-06")
      expect(signals[:profile][:adoption_priority]).not_to include("[phone]")
    end
  end

  describe "fingerprint" do
    it "is stable for identical signals" do
      create(:individual_profile, user: adopter, activity_level: "active")
      first = described_class.call(adopter: adopter)[:fingerprint]
      second = described_class.call(adopter: adopter)[:fingerprint]
      expect(first).to eq(second)
    end

    it "changes when a signal changes" do
      create(:individual_profile, user: adopter, activity_level: "active")
      before = described_class.call(adopter: adopter)[:fingerprint]

      create(:saved_pet, user: adopter, pet: create(:pet))
      after = described_class.call(adopter: adopter)[:fingerprint]

      expect(after).not_to eq(before)
    end
  end
end

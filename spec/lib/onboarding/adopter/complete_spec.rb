require "rails_helper"

RSpec.describe Onboarding::Adopter::Complete do
  describe "#call" do
    context "when all questions answered" do
      let(:user) do
        u = create(:user)
        profile = u.build_adopter_profile(
          weekend_activity: [ "going_for_walks" ],
          activity_level: "active",
          ideal_companion: "playful_companion",
          pet_experience: "some_experience",
          adoption_goals: [ "daily_companion" ],
          daily_time_available: "1_to_2h",
          personality: "friendly_social",
          adoption_priority: "a loving home",
          onboarding_step: 8
        )
        profile.save!
        u
      end

      it "completes onboarding" do
        result = described_class.call(user: user)
        expect(result).to be_success
        expect(result.data[:redirect_path]).to eq("/pets")
      end

      it "marks user onboarding as completed" do
        described_class.call(user: user)
        expect(user.reload).to be_onboarding_completed
      end
    end

    context "when not all questions answered" do
      let(:user) do
        u = create(:user)
        u.build_adopter_profile(weekend_activity: [ "going_for_walks" ], onboarding_step: 1).save!
        u
      end

      it "returns failure" do
        result = described_class.call(user: user)
        expect(result).to be_failure
      end
    end

    context "with skip flag" do
      let(:user) { create(:user) }

      it "creates profile if none exists" do
        result = described_class.call(user: user, skip: true)
        expect(result).to be_success
        expect(user.reload).to be_onboarding_completed
      end
    end

    context "without profile" do
      let(:user) { create(:user) }

      it "returns failure" do
        result = described_class.call(user: user)
        expect(result).to be_failure
      end
    end
  end
end

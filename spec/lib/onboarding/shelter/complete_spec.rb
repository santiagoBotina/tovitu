require "rails_helper"

RSpec.describe Onboarding::Shelter::Complete do
  describe "#call" do
    context "when all questions answered" do
      let(:user) do
        u = create(:user)
        profile = u.build_shelter_profile(
          organization_type: "small_rescue",
          pet_count_range: "under_20",
          adoption_involvement: "basic_screening",
          approval_priorities: [ "stable_home" ],
          communication_channels: [ "email" ],
          biggest_challenges: [ "finding_qualified_adopters" ],
          approval_philosophy: "best match for pet",
          onboarding_step: 7
        )
        profile.save!
        u
      end

      it "completes onboarding" do
        result = described_class.call(user: user)
        expect(result).to be_success
        expect(result.data[:redirect_path]).to eq("/shelters/new")
      end

      it "marks user onboarding as completed" do
        described_class.call(user: user)
        expect(user.reload).to be_onboarding_completed
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

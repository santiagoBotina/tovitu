require "rails_helper"

RSpec.describe Onboarding::Shelter::SaveResponse do
  let(:user) { create(:user) }

  describe "#call" do
    context "with valid question number" do
      it "saves the answer to shelter_profile" do
        described_class.call(user: user, question_number: 1, answer: "small_rescue")
        expect(user.shelter_profile.organization_type).to eq("small_rescue")
      end

      it "updates onboarding_step" do
        described_class.call(user: user, question_number: 2, answer: "under_20")
        expect(user.reload.onboarding_step).to eq(2)
      end

      it "returns success with metadata" do
        result = described_class.call(user: user, question_number: 1, answer: "small_rescue")
        expect(result).to be_success
        expect(result.data[:question_number]).to eq(1)
      end
    end

    context "with invalid question number" do
      it "returns failure" do
        result = described_class.call(user: user, question_number: 99, answer: "test")
        expect(result).to be_failure
      end
    end

    context "with jsonb field" do
      it "coerces answer to array" do
        described_class.call(user: user, question_number: 4, answer: "stable_home")
        expect(user.shelter_profile.approval_priorities).to eq([ "stable_home" ])
      end
    end

    context "on last question" do
      it "marks as complete" do
        result = described_class.call(user: user, question_number: 7, answer: "best match")
        expect(result.data[:complete]).to be true
      end
    end
  end
end

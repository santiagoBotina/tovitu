require "rails_helper"

RSpec.describe Onboarding::Adopter::SaveResponse do
  let(:user) { create(:user) }

  describe "#call" do
    context "with valid question number" do
      it "saves the answer to adopter_profile" do
        described_class.call(user: user, question_number: 2, answer: "active")
        expect(user.adopter_profile.activity_level).to eq("active")
      end

      it "updates onboarding_step" do
        described_class.call(user: user, question_number: 3, answer: "playful_companion")
        expect(user.reload.onboarding_step).to eq(3)
      end

      it "returns success with metadata" do
        result = described_class.call(user: user, question_number: 1, answer: [ "going_for_walks" ])
        expect(result).to be_success
        expect(result.data[:question_number]).to eq(1)
        expect(result.data[:onboarding_step]).to eq(1)
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
        described_class.call(user: user, question_number: 1, answer: "going_for_walks")
        expect(user.adopter_profile.weekend_activity).to eq([ "going_for_walks" ])
      end

      it "accepts array answer" do
        described_class.call(user: user, question_number: 1, answer: [ "going_for_walks", "outdoor_adventures" ])
        expect(user.adopter_profile.weekend_activity).to eq([ "going_for_walks", "outdoor_adventures" ])
      end
    end

    context "on last question" do
      it "marks as complete" do
        result = described_class.call(user: user, question_number: 8, answer: "some priority")
        expect(result.data[:complete]).to be true
      end
    end
  end
end

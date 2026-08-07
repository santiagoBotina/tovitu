require "rails_helper"

RSpec.describe Onboarding::Individual::SaveResponse do
  let(:user) { create(:user) }

  describe "#call" do
    context "with valid question number" do
      it "saves the answer to individual_profile" do
        described_class.call(user: user, question_number: 1, answer: "going_for_walks")
        expect(user.individual_profile.weekend_activity).to eq([ "going_for_walks" ])
      end

      it "updates onboarding_step" do
        described_class.call(user: user, question_number: 2, answer: "active")
        expect(user.reload.onboarding_step).to eq(2)
      end

      it "returns success with metadata" do
        result = described_class.call(user: user, question_number: 2, answer: "active")
        expect(result).to be_success
        expect(result.data[:question_number]).to eq(2)
      end
    end

    context "with invalid question number" do
      it "returns failure" do
        result = described_class.call(user: user, question_number: 99, answer: "test")
        expect(result).to be_failure
      end
    end

    context "with jsonb field" do
      it "coerces a single answer to an array" do
        described_class.call(user: user, question_number: 1, answer: "going_for_walks")
        expect(user.individual_profile.weekend_activity).to eq([ "going_for_walks" ])
      end

      it "coerces multiple answers to an array" do
        described_class.call(user: user, question_number: 1, answer: [ "going_for_walks", "active" ])
        expect(user.individual_profile.weekend_activity).to eq([ "going_for_walks", "active" ])
      end
    end

    context "on last question" do
      it "marks as complete" do
        result = described_class.call(user: user, question_number: 8, answer: "a loving home")
        expect(result.data[:complete]).to be true
      end
    end

    context "with a text answer longer than the question max_length" do
      it "rejects without saving" do
        result = described_class.call(user: user, question_number: 8, answer: "x" * 201)
        expect(result).to be_failure
        expect(user.individual_profile).to be_nil
      end

      it "accepts an answer at exactly max_length" do
        result = described_class.call(user: user, question_number: 8, answer: "x" * 200)
        expect(result).to be_success
        expect(user.individual_profile.adoption_priority).to eq("x" * 200)
      end

      it "returns the localized error message" do
        result = described_class.call(user: user, question_number: 8, answer: "x" * 201)
        expect(result.errors).to include(I18n.t("errors.onboarding.answer_too_long", max_length: 200))
      end
    end

    context "with an existing profile" do
      it "does not wipe onboarding completion when editing from review" do
        user.update!(onboarding_completed_at: Time.current)
        profile = create(:individual_profile, user: user, activity_level: "active", onboarding_step: 8)
        completed_at = user.onboarding_completed_at

        described_class.call(user: user, question_number: 2, answer: "very_active")

        expect(profile.reload.activity_level).to eq("very_active")
        expect(user.reload.onboarding_completed_at).to eq(completed_at)
      end
    end
  end
end

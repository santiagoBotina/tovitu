require "rails_helper"

RSpec.describe Gamification::Journey do
  let(:user) { create(:user, :verified) }

  subject(:journey) { described_class.new(user) }

  describe "#current_stage" do
    it "returns getting_started for a fresh user" do
      expect(journey.current_stage[:key]).to eq(:getting_started)
    end

    it "returns building_profile once onboarding is complete" do
      user.update!(onboarding_completed_at: Time.current)
      expect(journey.current_stage[:key]).to eq(:building_profile)
    end

    it "returns discovering_matches once onboarding is complete and a pet is saved" do
      user.update!(onboarding_completed_at: Time.current)
      create(:saved_pet, user: user)
      expect(journey.current_stage[:key]).to eq(:discovering_matches)
    end

    it "returns ready_to_adopt once there is an active request" do
      user.update!(onboarding_completed_at: Time.current)
      create(:adoption_request, adopter: user, status: :pending)
      expect(journey.current_stage[:key]).to eq(:ready_to_adopt)
    end
  end

  describe "#stages" do
    it "marks earlier stages as reached and later ones as not" do
      user.update!(onboarding_completed_at: Time.current)
      stages = journey.stages
      expect(stages.find { |s| s[:key] == :getting_started }[:reached]).to be(true)
      expect(stages.find { |s| s[:key] == :building_profile }[:reached]).to be(true)
      expect(stages.find { |s| s[:key] == :discovering_matches }[:reached]).to be(false)
      expect(stages.find { |s| s[:key] == :ready_to_adopt }[:reached]).to be(false)
    end
  end

  describe "#milestones" do
    it "reports all milestones locked for a fresh user" do
      milestones = journey.milestones
      expect(milestones.map { |m| m[:done] }).to all(be(false))
    end

    it "unlocks profile_starter when onboarding is complete" do
      user.update!(onboarding_completed_at: Time.current)
      milestone = journey.milestones.find { |m| m[:key] == :profile_starter }
      expect(milestone[:done]).to be(true)
    end

    it "unlocks first_saved_pet when a pet is saved" do
      create(:saved_pet, user: user)
      milestone = journey.milestones.find { |m| m[:key] == :first_saved_pet }
      expect(milestone[:done]).to be(true)
    end

    it "unlocks first_application when a request is submitted" do
      create(:adoption_request, adopter: user, status: :pending)
      milestone = journey.milestones.find { |m| m[:key] == :first_application }
      expect(milestone[:done]).to be(true)
    end

    it "unlocks active_applicant when a request is in review" do
      create(:adoption_request, adopter: user, status: :in_validation)
      milestone = journey.milestones.find { |m| m[:key] == :active_applicant }
      expect(milestone[:done]).to be(true)
    end

    it "does not unlock active_applicant for a declined request" do
      create(:adoption_request, adopter: user, status: :declined)
      milestone = journey.milestones.find { |m| m[:key] == :active_applicant }
      expect(milestone[:done]).to be(false)
    end

    it "unlocks publisher when the user publishes a pet" do
      create(:pet, :individual_listed, publisher: user)
      milestone = journey.milestones.find { |m| m[:key] == :publisher }
      expect(milestone[:done]).to be(true)
    end
  end

  describe "#next_milestone" do
    it "returns the first locked milestone" do
      expect(journey.next_milestone[:key]).to eq(:profile_starter)
    end

    it "returns nil when all milestones are complete" do
      user.update!(onboarding_completed_at: Time.current)
      create(:saved_pet, user: user)
      create(:adoption_request, adopter: user, status: :in_validation)
      create(:pet, :individual_listed, publisher: user)
      expect(journey.next_milestone).to be_nil
    end
  end

  describe "#sidebar_label_key" do
    it "maps the current stage to a label key" do
      expect(journey.sidebar_label_key).to eq(:label_getting_started)
    end
  end

  describe "#next_step_key" do
    it "prompts profile completion when onboarding is incomplete" do
      expect(journey.next_step_key).to eq(:next_complete_profile)
    end

    it "prompts saving a pet when onboarding is complete but no pets are saved" do
      user.update!(onboarding_completed_at: Time.current)
      expect(journey.next_step_key).to eq(:next_save_pet)
    end

    it "prompts submitting a request when pets are saved but no active request exists" do
      user.update!(onboarding_completed_at: Time.current)
      create(:saved_pet, user: user)
      expect(journey.next_step_key).to eq(:next_submit_request)
    end

    it "prompts submitting a new request when the only request was declined" do
      user.update!(onboarding_completed_at: Time.current)
      create(:saved_pet, user: user)
      create(:adoption_request, adopter: user, status: :declined)
      expect(journey.next_step_key).to eq(:next_submit_request)
    end

    it "reports awaiting review when there is an active request" do
      user.update!(onboarding_completed_at: Time.current)
      create(:saved_pet, user: user)
      create(:adoption_request, adopter: user, status: :pending)
      expect(journey.next_step_key).to eq(:next_await_review)
    end
  end

  describe "#missing_step" do
    it "points to profile completion when onboarding is incomplete" do
      step = journey.missing_step
      expect(step[:key]).to eq(:complete_profile)
      expect(step[:path]).to eq(:profile_onboarding_path)
    end

    it "points to saving a pet when onboarding is complete but no pets are saved" do
      user.update!(onboarding_completed_at: Time.current)
      step = journey.missing_step
      expect(step[:key]).to eq(:save_pet)
    end

    it "returns nil when the user has saved pets and submitted a request" do
      user.update!(onboarding_completed_at: Time.current)
      create(:saved_pet, user: user)
      create(:adoption_request, adopter: user, status: :pending)
      expect(journey.missing_step).to be_nil
    end
  end
end

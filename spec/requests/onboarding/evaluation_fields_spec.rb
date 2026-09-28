require "rails_helper"

# Plan-49 structured adopter fields (date of birth, home environment, other
# pets) — new adopters must answer them to complete onboarding; existing
# adopters are never blocked and see a gentle prompt (REQ-49-13, AC-49-14).
RSpec.describe "Adopter evaluation fields", type: :request do
  let(:adopter) { create(:user, :verified) }

  def sign_in(user)
    post session_path(locale: :en), params: { session: { email: user.email, password: "password123" } }
  end

  def patch_answer(question_number, answer)
    patch onboarding_individual_questions_path,
          params: { question_number: question_number, answer: answer }.to_json,
          headers: { "Content-Type" => "application/json" }
  end

  def complete_answers
    {
      1 => %w[going_for_walks],
      2 => "active",
      3 => "playful_companion",
      4 => "some_experience",
      5 => %w[daily_companion],
      6 => "2_to_4h",
      7 => "adventurous_energetic",
      8 => "A loving home"
    }
  end

  describe "new adopter completion requires the new questions" do
    before { sign_in adopter }

    it "blocks completion when the evaluation fields are unanswered" do
      complete_answers.each { |qnum, answer| patch_answer(qnum, answer) }

      post onboarding_individual_completion_path, params: { skip: "false" }

      expect(adopter.reload).not_to be_onboarding_completed
      expect(response).to redirect_to(onboarding_individual_questions_path)
    end

    it "saves the new fields through the wizard" do
      complete_answers.each { |qnum, answer| patch_answer(qnum, answer) }
      patch_answer(9, "1994-05-10")
      patch_answer(10, "house_with_fenced_yard")
      patch_answer(11, "no_other_pets")

      post onboarding_individual_completion_path, params: { skip: "false" }

      profile = adopter.reload.individual_profile
      expect(adopter).to be_onboarding_completed
      expect(profile.date_of_birth).to eq(Date.new(1994, 5, 10))
      expect(profile.home_environment).to eq("house_with_fenced_yard")
      expect(profile.other_pets).to eq("no_other_pets")
    end
  end

  describe "existing adopters are never blocked" do
    let(:pet) { create(:pet, shelter: create(:shelter)) }
    let(:existing) { create(:user, :verified, :onboarding_completed) }

    before do
      create(:individual_profile, user: existing, activity_level: "active", onboarding_step: 11)
      sign_in existing
    end

    it "can still open the adoption request form with missing new fields" do
      get new_adoption_request_path(pet_id: pet.id)

      expect(response).to have_http_status(:ok)
    end

    it "does not wipe onboarding completion when editing an answer from review" do
      completed_at = existing.onboarding_completed_at
      patch onboarding_individual_questions_path,
            params: { question_number: 2, answer: "very_active", from_profile: "true" }

      expect(existing.reload.onboarding_completed_at).to eq(completed_at)
    end
  end

  describe "profile settings prompt (gentle, non-blocking)" do
    it "shows the prompt when the new fields are missing" do
      existing = create(:user, :verified, :onboarding_completed)
      create(:individual_profile, user: existing, activity_level: "active", onboarding_step: 11)
      sign_in existing

      get edit_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.profiles.edit.evaluation_fields_title"))
    end

    it "does not show the prompt when the new fields are complete" do
      existing = create(:user, :verified, :onboarding_completed)
      create(:individual_profile, user: existing, activity_level: "active", onboarding_step: 11,
             date_of_birth: 30.years.ago.to_date, home_environment: "house_with_fenced_yard",
             other_pets: "no_other_pets")
      sign_in existing

      get edit_profile_path

      expect(response.body).not_to include(I18n.t("authentication.profiles.edit.evaluation_fields_title"))
    end
  end

  describe "one-time notice near the request flow" do
    let(:pet) { create(:pet, shelter: create(:shelter)) }

    before do
      existing = create(:user, :verified, :onboarding_completed)
      create(:individual_profile, user: existing, activity_level: "active", onboarding_step: 11)
      sign_in existing
    end

    it "shows the notice on the first visit to the request form" do
      get new_adoption_request_path(pet_id: pet.id)

      expect(response.body).to include(I18n.t("adoption_requests.new.evaluation_fields_notice"))
    end

    it "does not show it again on a later visit (at most once)" do
      get new_adoption_request_path(pet_id: pet.id)
      get new_adoption_request_path(pet_id: pet.id)

      expect(response.body).not_to include(I18n.t("adoption_requests.new.evaluation_fields_notice"))
    end
  end
end

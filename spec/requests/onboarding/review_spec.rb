require "rails_helper"

# Regression coverage for onboarding bugfix plan bug 1.2:
# from the profile page, completed users see a full review of their
# onboarding answers and can edit any of them in place.
RSpec.describe "Onboarding review page" do
  def sign_in(user, locale: :en)
    post session_path(locale: locale), params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /profile/onboarding (individual)" do
    it "renders every question with the current answer, not the last wizard step" do
      user = create(:user, :verified, :onboarding_completed, role: "individual")
      create(:individual_profile, user: user, activity_level: "active", personality: "calm_thoughtful", onboarding_step: 8)

      sign_in user
      get profile_onboarding_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("onboarding.individual.review.title"))
      # All 8 question texts render, not just the last one.
      (1..8).each do |n|
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q#{n}.text"))
      end
      # Stored answers render as their localized labels.
      expect(response.body).to include(I18n.t("onboarding.individual.questions.q2.options.active"))
      expect(response.body).to include(I18n.t("onboarding.individual.questions.q7.options.calm_thoughtful"))
    end

    it "flags unanswered questions instead of crashing" do
      user = create(:user, :verified, :onboarding_completed, role: "individual")
      create(:individual_profile, user: user, activity_level: "", adoption_goals: [], onboarding_step: 8)

      sign_in user
      get profile_onboarding_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("onboarding.review.not_answered"))
    end

    it "opens every editor when edit_all is requested" do
      user = create(:user, :verified, :onboarding_completed, role: "individual")
      create(:individual_profile, user: user, activity_level: "active", onboarding_step: 8)

      sign_in user
      get profile_onboarding_path(locale: :en, edit_all: true)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-review-question="1"')
      # All editors are rendered open.
      expect(response.body.scan('<details class="review-edit mt-4 group" open>').size).to eq(8)
    end
  end

  describe "PATCH /onboarding/individual/questions (edit from review)" do
    it "saves the answer via SaveResponse and returns to the review page" do
      user = create(:user, :verified, :onboarding_completed, role: "individual")
      create(:individual_profile, user: user, activity_level: "active", onboarding_step: 8)
      completed_at = user.onboarding_completed_at

      sign_in user
      patch onboarding_individual_questions_path(locale: :en),
        params: { question_number: 2, answer: "very_active", from_profile: "true" }

      expect(response).to redirect_to("/en/profile/onboarding")
      expect(flash[:notice]).to be_present
      expect(user.individual_profile.reload.activity_level).to eq("very_active")
      # Editing must never wipe onboarding completion.
      expect(user.reload.onboarding_completed_at).to eq(completed_at)
    end
  end

  describe "GET /profile/shelter_onboarding (shelter)" do
    it "renders every question plus the personality card" do
      shelter = create(:shelter)
      user = create(:user, :verified, :onboarding_completed, role: "shelter_admin", shelter: shelter)
      create(:shelter_profile, user: user, organization_type: "large_shelter",
        biggest_challenges: [ "managing_applications" ], onboarding_step: 7)

      sign_in user
      get profile_shelter_onboarding_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("onboarding.shelter.review.title"))
      expect(response.body).to include(I18n.t("onboarding.shelter.personality.process_pro.name"))
    end
  end

  describe "PATCH /onboarding/shelter/questions (edit from review)" do
    it "saves the answer, returns to review, and recalculates the personality" do
      shelter = create(:shelter)
      user = create(:user, :verified, :onboarding_completed, role: "shelter_admin", shelter: shelter)
      create(:shelter_profile, user: user, organization_type: "large_shelter",
        adoption_involvement: "basic_screening", onboarding_step: 7)
      completed_at = user.onboarding_completed_at

      sign_in user
      patch onboarding_shelter_questions_path(locale: :en),
        params: { question_number: 1, answer: "small_rescue", from_profile: "true" }

      expect(response).to redirect_to("/en/profile/shelter_onboarding")
      expect(user.shelter_profile.reload.organization_type).to eq("small_rescue")
      expect(user.reload.onboarding_completed_at).to eq(completed_at)

      get profile_shelter_onboarding_path(locale: :en)
      expect(response.body).to include(I18n.t("onboarding.shelter.personality.heart_led.name"))
    end
  end

  describe "GET /profile/shelter_onboarding edit_all" do
    it "opens every editor for shelter questions" do
      shelter = create(:shelter)
      user = create(:user, :verified, :onboarding_completed, role: "shelter_admin", shelter: shelter)
      create(:shelter_profile, user: user, organization_type: "large_shelter", onboarding_step: 7)

      sign_in user
      get profile_shelter_onboarding_path(locale: :en, edit_all: true)

      expect(response).to have_http_status(:ok)
      # All 7 editors are rendered open.
      expect(response.body.scan('<details class="review-edit mt-4 group" open>').size).to eq(7)
    end
  end

  describe "editing from review keeps the user's locale" do
    it "returns a Spanish-speaking individual to the Spanish review page" do
      user = create(:user, :verified, :onboarding_completed, role: "individual", locale: "es")
      create(:individual_profile, user: user, activity_level: "active", onboarding_step: 8)

      sign_in user
      patch onboarding_individual_questions_path(locale: :es),
        params: { question_number: 2, answer: "very_active", from_profile: "true" }

      expect(response).to redirect_to("/es/profile/onboarding")
      follow_redirect!
      expect(response.body).to include(I18n.t("onboarding.individual.review.title", locale: :es))
    end
  end

  describe "wizard guard for completed users" do
    it "redirects a completed individual away from the wizard" do
      user = create(:user, :verified, :onboarding_completed, role: "individual")
      create(:individual_profile, user: user, activity_level: "active", onboarding_step: 8)

      sign_in user
      get onboarding_individual_questions_path(locale: :en)

      expect(response).to redirect_to("/en/dashboard")
      expect(flash[:notice]).to eq(I18n.t("flash.onboarding.already_complete"))
    end

    it "redirects a completed shelter admin away from the wizard" do
      shelter = create(:shelter)
      user = create(:user, :verified, :onboarding_completed, role: "shelter_admin", shelter: shelter)
      create(:shelter_profile, user: user, organization_type: "large_shelter", onboarding_step: 7)

      sign_in user
      get onboarding_shelter_questions_path(locale: :en)

      expect(response).to redirect_to("/en/shelters/#{shelter.id}/dashboard")
      expect(flash[:notice]).to eq(I18n.t("flash.onboarding.already_complete"))
    end
  end
end

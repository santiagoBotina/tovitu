require "rails_helper"

# Regression coverage for onboarding bugfix plan (bugs 1.3 & 1.4):
# the legacy "adopter" namespace is a deprecated alias for "individual".
# Legacy URLs must live on only as permanent, locale-preserving redirects,
# and first login must route incomplete users to the real onboarding wizard.
RSpec.describe "Legacy adopter routes" do
  describe "GET /onboarding/adopter/questions" do
    it "permanently redirects to the individual questions (en)" do
      get onboarding_adopter_onboarding_questions_path(locale: :en)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/en/onboarding/individual/questions")
    end

    it "preserves a non-default locale (es)" do
      get onboarding_adopter_onboarding_questions_path(locale: :es)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/es/onboarding/individual/questions")
    end
  end

  describe "GET /onboarding/adopter/completion" do
    it "permanently redirects to the individual completion (en)" do
      get onboarding_adopter_onboarding_completion_path(locale: :en)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/en/onboarding/individual/completion")
    end

    it "preserves a non-default locale (es)" do
      get onboarding_adopter_onboarding_completion_path(locale: :es)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/es/onboarding/individual/completion")
    end
  end

  describe "POST /session (first login)" do
    it "routes an incomplete individual to the individual onboarding wizard" do
      user = create(:user, :verified, role: "individual")
      post session_path(locale: :en), params: { session: { email: user.email, password: "password123" } }
      expect(response).to redirect_to("/en/onboarding/individual/questions")
    end

    it "routes an incomplete shelter admin to the shelter onboarding wizard" do
      user = create(:user, :verified, role: "shelter_admin")
      post session_path(locale: :en), params: { session: { email: user.email, password: "password123" } }
      expect(response).to redirect_to("/en/onboarding/shelter/questions")
    end

    it "routes a completed individual to the user dashboard" do
      user = create(:user, :verified, :onboarding_completed, role: "individual")
      post session_path(locale: :en), params: { session: { email: user.email, password: "password123" } }
      expect(response).to redirect_to("/en/dashboard")
    end

    it "routes a completed shelter admin with a shelter to the shelter dashboard" do
      shelter = create(:shelter)
      user = create(:user, :verified, :onboarding_completed, role: "shelter_admin", shelter: shelter)
      post session_path(locale: :en), params: { session: { email: user.email, password: "password123" } }
      expect(response).to redirect_to("/en/shelters/#{shelter.id}/dashboard")
    end
  end
end

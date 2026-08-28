require "rails_helper"

# REQ-04 — Redirect to Login when applying without authentication.
# A signed-out visitor can browse freely, but committing to apply requires
# authentication; after authenticating they land back in the application flow
# for the same pet, and no request is ever created before auth completes.
RSpec.describe "Authentication return-to flow", type: :request do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }

  describe "signed-out visitor applying to adopt" do
    it "redirects to login when tapping apply" do
      get new_adoption_request_path(pet_id: pet.id)
      expect(response).to redirect_to(new_session_path)
    end

    it "does not create an adoption request before authentication" do
      expect {
        get new_adoption_request_path(pet_id: pet.id)
      }.not_to change(AdoptionRequest, :count)
    end

    it "returns the user to the application form for the same pet after login" do
      get new_adoption_request_path(pet_id: pet.id)
      post session_path, params: { session: { email: adopter.email, password: "password123" } }

      expect(response).to redirect_to(new_adoption_request_path(pet_id: pet.id))
    end

    it "shows a friendly reason banner on the login page" do
      get new_adoption_request_path(pet_id: pet.id)
      get new_session_path

      expect(response.body).to include(I18n.t("authentication.sessions.new.apply_intent_title"))
      expect(response.body).to include(pet.name)
    end

    it "leaves no request behind when the login is abandoned" do
      get new_adoption_request_path(pet_id: pet.id)
      get new_session_path

      expect(AdoptionRequest.count).to eq(0)
    end

    context "when the pet becomes unavailable while authenticating" do
      it "redirects to browse with a clear, non-technical message" do
        get new_adoption_request_path(pet_id: pet.id)
        pet.update!(status: :adopted, adopted_at: Time.current)

        post session_path, params: { session: { email: adopter.email, password: "password123" } }
        expect(response).to redirect_to(new_adoption_request_path(pet_id: pet.id))

        follow_redirect!
        expect(response).to redirect_to(pets_path)

        follow_redirect!
        expect(response.body).to include(I18n.t("adoptions.requests.errors.pet_not_available"))
      end
    end
  end

  describe "navbar-initiated login" do
    it "does not surprise-redirect after a direct login" do
      # A stale return path from an abandoned apply flow must not hijack a
      # login started from the navbar. The redirect's flash is consumed when
      # the login page first renders; a later direct visit to login (as if via
      # the navbar) drops the stale path.
      get new_adoption_request_path(pet_id: pet.id)
      get new_session_path
      get root_path
      get new_session_path

      post session_path, params: { session: { email: adopter.email, password: "password123" } }
      expect(response).to redirect_to(user_dashboard_path)
    end

    it "does not surprise-redirect after a deep link to the role-specific login" do
      get new_adoption_request_path(pet_id: pet.id)
      get new_session_path
      get root_path
      get login_individual_path(locale: :en)

      post session_path, params: { session: { email: adopter.email, password: "password123" } }
      expect(response).to redirect_to(user_dashboard_path)
    end
  end

  describe "onboarding requirement" do
    let(:unonboarded) { create(:user, :verified) }

    it "routes through onboarding and returns to the application afterwards" do
      get new_adoption_request_path(pet_id: pet.id)
      post session_path, params: { session: { email: unonboarded.email, password: "password123" } }
      expect(response).to redirect_to("/en/onboarding/individual/questions")

      post onboarding_individual_completion_path, params: { skip: "true" }
      expect(response).to redirect_to(new_adoption_request_path(pet_id: pet.id))
    end
  end

  describe "account creation instead of login" do
    it "returns to the application after the full sign-up + verification flow" do
      get new_adoption_request_path(pet_id: pet.id)

      post registration_path, params: {
        user: {
          name: "New Adopter",
          email: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
      expect(response).to redirect_to(check_email_registration_path)

      user = User.find_by(email: "new@example.com")
      token = create(:email_verification_token, user: user)
      get verification_path(token: token.token)
      expect(response).to redirect_to("/en/onboarding/individual/questions")

      post onboarding_individual_completion_path, params: { skip: "true" }
      expect(response).to redirect_to(new_adoption_request_path(pet_id: pet.id))
    end
  end
end

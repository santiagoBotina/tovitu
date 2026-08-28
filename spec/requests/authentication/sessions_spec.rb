require "rails_helper"

RSpec.describe "Sessions" do
  describe "GET /login/adopter" do
    it "permanently redirects to the individual login (locale preserved)" do
      get login_adopter_path(locale: :en)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/en/login/individual")
    end

    it "permanently redirects preserving a non-default locale" do
      get login_adopter_path(locale: :es)
      expect(response).to redirect_to("/es/login/individual")
    end
  end

  describe "GET /login/individual" do
    it "renders the individual login in English by default" do
      get login_individual_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.sessions.new_individual.title", locale: :en))
    end

    it "renders the individual login in Spanish when locale is es" do
      get login_individual_path(locale: :es)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.sessions.new_individual.title", locale: :es))
      expect(response.body).to include(I18n.t("authentication.sessions.new_individual.submit", locale: :es))
      expect(response.body).not_to include("Welcome back")
    end

    it "renders the role toggle labels in Spanish" do
      get login_individual_path(locale: :es)
      expect(response.body).to include(I18n.t("authentication.role_toggle.individual", locale: :es))
      expect(response.body).to include(I18n.t("authentication.role_toggle.shelter", locale: :es))
    end
  end

  describe "GET /login/shelter" do
    it "renders the shelter login in Spanish when locale is es" do
      get login_shelter_path(locale: :es)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.sessions.new_shelter.title", locale: :es))
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      let(:user) { create(:user, :verified, :onboarding_completed) }

      it "logs the user in" do
        post session_path, params: { session: { email: user.email, password: "password123" } }
      expect(response).to redirect_to(user_dashboard_path)
    end

    it "sets session user_id" do
      post session_path, params: { session: { email: user.email, password: "password123" } }
      expect(session[:user_id]).to eq(user.id)
      end

      it "logs a successful login attempt" do
        expect { post session_path, params: { session: { email: user.email, password: "password123" } } }
          .to change(LoginAttempt, :count).by(1)
        expect(LoginAttempt.last).to be_success
      end
    end

    context "with unverified account" do
      let(:user) { create(:user) }

      it "does not log the user in" do
        post session_path, params: { session: { email: user.email, password: "password123" } }
        expect(session[:user_id]).to be_nil
      end

      it "shows an error message" do
        post session_path, params: { session: { email: user.email, password: "password123" } }
        expect(flash[:alert]).to include("verify your email")
      end

      it "resends verification email" do
        expect { post session_path, params: { session: { email: user.email, password: "password123" } } }
          .to have_enqueued_mail(AuthenticationMailer, :verification)
      end
    end

    context "with invalid credentials" do
      let(:user) { create(:user, :verified) }

      it "does not log the user in" do
        post session_path, params: { session: { email: user.email, password: "wrongpassword" } }
        expect(session[:user_id]).to be_nil
      end

      it "shows a generic error" do
        post session_path, params: { session: { email: user.email, password: "wrongpassword" } }
        expect(flash[:alert]).to include("Invalid email or password")
      end

      it "shows a localized error in Spanish" do
        post session_path(locale: :es), params: { session: { email: user.email, password: "wrongpassword" } }
        expect(flash[:alert]).to include(I18n.t("errors.authenticate_user.invalid", locale: :es))
        expect(flash[:alert]).not_to include("Invalid email or password")
      end

      it "logs a failed login attempt" do
        expect { post session_path, params: { session: { email: user.email, password: "wrongpassword" } } }
          .to change(LoginAttempt, :count).by(1)
        expect(LoginAttempt.last).not_to be_success
      end
    end

    context "with rate limiting" do
      let(:email) { "test@example.com" }
      let!(:user) { create(:user, :verified, email: email) }

      it "locks account after 5 failed attempts" do
        5.times do
          post session_path, params: { session: { email: email, password: "wrongpassword" } }
        end

        post session_path, params: { session: { email: email, password: "password123" } }
        expect(session[:user_id]).to be_nil
        expect(flash[:alert]).to include("locked")
      end
    end

    context "with non-existent email" do
      it "shows generic error" do
        post session_path, params: { session: { email: "nonexistent@example.com", password: "password123" } }
        expect(flash[:alert]).to include("Invalid email or password")
      end
    end
  end

  describe "DELETE /session" do
    it "logs the user out" do
      user = create(:user, :verified)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      delete session_path
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
    end
  end
end

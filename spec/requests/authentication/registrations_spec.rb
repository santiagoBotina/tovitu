require "rails_helper"

RSpec.describe "Registrations" do
  describe "GET /registration/new" do
    it "renders the registration form" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create an account")
    end

    it "redirects to root if already logged in" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get new_registration_path
      expect(response).to redirect_to(user_dashboard_path)
    end
  end

  describe "POST /registration" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          user: {
            name: "Jane Doe",
            email: "jane@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "creates a new user" do
        expect { post registration_path, params: valid_params }
          .to change(User, :count).by(1)
      end

      it "creates an unverified user" do
        post registration_path, params: valid_params
        expect(User.last).not_to be_verified
      end

      it "sends a verification email" do
        expect { post registration_path, params: valid_params }
          .to have_enqueued_mail(AuthenticationMailer, :verification)
      end

      it "redirects to check email page" do
        post registration_path, params: valid_params
        expect(response).to redirect_to(check_email_registration_path)
      end

      it "sets adopter role by default" do
        post registration_path, params: valid_params
        expect(User.last.role).to eq("adopter")
      end
    end

    context "with invalid parameters" do
      it "re-renders the form when password is too short" do
        post registration_path, params: { user: { name: "Jane", email: "jane@example.com", password: "short", password_confirmation: "short" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("too short")
      end

      it "re-renders the form when passwords don't match" do
        post registration_path, params: { user: { name: "Jane", email: "jane@example.com", password: "password123", password_confirmation: "different" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders the form with invalid email" do
        post registration_path, params: { user: { name: "Jane", email: "invalid", password: "password123", password_confirmation: "password123" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects duplicate email" do
        create(:user, email: "jane@example.com")
        post registration_path, params: { user: { name: "Jane", email: "jane@example.com", password: "password123", password_confirmation: "password123" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("already been taken")
      end
    end
  end
end

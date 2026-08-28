require "rails_helper"

RSpec.describe "Registrations" do
  describe "GET /registration/new" do
    it "renders the registration form" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create account")
    end

    it "redirects to root if already logged in" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get new_registration_path
      expect(response).to redirect_to(user_dashboard_path)
    end

    it "renders the individual variant for the deprecated adopter role param" do
      get new_registration_path, params: { role: "adopter" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.registrations.new.title_individual"))
    end

    it "renders the shelter variant for the shelter_admin role param" do
      get new_registration_path, params: { role: "shelter_admin" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.registrations.new.title_shelter"))
      expect(response.body).to include('data-role-toggle-role="shelter"')
      # The hidden role field keeps the real role so the account registers correctly.
      expect(response.body).to include('value="shelter_admin"')
    end

    it "renders the registration form in Spanish when locale is es" do
      get new_registration_path(locale: :es)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.registrations.new.title_individual", locale: :es))
      expect(response.body).to include(I18n.t("authentication.registrations.new.submit", locale: :es))
      expect(response.body).not_to include("Create account")
    end

    it "renders the shelter registration variant in Spanish" do
      get new_registration_path(locale: :es, params: { role: "shelter_admin" })
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.registrations.new.title_shelter", locale: :es))
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

      it "sets individual role by default" do
        post registration_path, params: valid_params
        expect(User.last.role).to eq("individual")
      end
    end

    context "with the deprecated adopter role" do
      it "registers the user as an individual" do
        post registration_path, params: {
          user: {
            name: "Jane Doe",
            email: "jane@example.com",
            password: "password123",
            password_confirmation: "password123",
            role: "adopter"
          }
        }
        expect(response).to redirect_to(check_email_registration_path)
        expect(User.last.role).to eq("individual")
      end
    end

    context "with the shelter role" do
      it "registers the user as a shelter_admin (what the Shelter toggle submits)" do
        expect {
          post registration_path, params: {
            user: {
              name: "Shelter Admin",
              email: "shelter@example.com",
              password: "password123",
              password_confirmation: "password123",
              role: "shelter_admin"
            }
          }
        }.to change(User, :count).by(1)
        expect(response).to redirect_to(check_email_registration_path)
        expect(User.last.role).to eq("shelter_admin")
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

      it "shows localized validation errors in Spanish" do
        post registration_path(locale: :es), params: { user: { name: "Jane", email: "jane@example.com", password: "short", password_confirmation: "short" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Contraseña es demasiado corto (mínimo 8 caracteres)")
        expect(response.body).not_to include("too short")
      end

      it "shows localized duplicate-email errors in Spanish" do
        create(:user, email: "jane@example.com")
        post registration_path(locale: :es), params: { user: { name: "Jane", email: "jane@example.com", password: "password123", password_confirmation: "password123" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Correo electrónico ya está en uso")
        expect(response.body).not_to include("already been taken")
      end
    end
  end
end

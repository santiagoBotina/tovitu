require "rails_helper"

RSpec.describe "Profiles" do
  describe "GET /profile/edit" do
    it "redirects to login when not authenticated" do
      get edit_profile_path
      expect(response).to redirect_to(root_path)
    end

    it "renders the edit form when logged in" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get edit_profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit profile")
    end
  end

  describe "PATCH /profile" do
    it "redirects to login when not authenticated" do
      patch profile_path, params: { user: { name: "New Name" } }
      expect(response).to redirect_to(root_path)
    end

    context "when logged in" do
      let(:user) { create(:user, :verified, :onboarding_completed) }

      before do
        post session_path, params: { session: { email: user.email, password: "password123" } }
      end

      it "updates the name" do
        patch profile_path, params: { user: { name: "New Name", email: user.email } }
        expect(user.reload.name).to eq("New Name")
      end

      it "redirects with success notice" do
        patch profile_path, params: { user: { name: "New Name", email: user.email } }
        expect(response).to redirect_to(edit_profile_path)
      end

      context "when changing email" do
        let(:new_email) { "newemail@example.com" }

        it "updates the email" do
          patch profile_path, params: { user: { name: user.name, email: new_email } }
          expect(user.reload.email).to eq(new_email)
        end

        it "marks email as unverified" do
          patch profile_path, params: { user: { name: user.name, email: new_email } }
          expect(user.reload).not_to be_verified
        end

        it "sends a verification email to the new address" do
          expect { patch profile_path, params: { user: { name: user.name, email: new_email } } }
            .to have_enqueued_mail(AuthenticationMailer, :verification)
        end
      end

      context "with invalid data" do
        it "re-renders the form with errors" do
          patch profile_path, params: { user: { name: "", email: user.email } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "Profile personalization sections" do
    context "as an adopter with completed onboarding" do
      let(:user) { create(:user, :verified, :onboarding_completed) }

      before do
        post session_path, params: { session: { email: user.email, password: "password123" } }
        get edit_profile_path
      end

      it "shows the preferences section" do
        expect(response.body).to include(I18n.t("authentication.profiles.edit.edit_preferences_title"))
      end

      it "shows the edit preferences link" do
        expect(response.body).to include(profile_onboarding_path(from_profile: true))
      end

      it "does not show shelter information section" do
        expect(response.body).not_to include(I18n.t("authentication.profiles.edit.shelter_info_title"))
      end
    end

    context "as a shelter user with completed onboarding and a shelter" do
      let(:shelter) { create(:shelter) }
      let(:user) { create(:user, :verified, :onboarding_completed, :shelter_admin, shelter: shelter) }

      before do
        post session_path, params: { session: { email: user.email, password: "password123" } }
        get edit_profile_path
      end

      it "shows the preferences section" do
        expect(response.body).to include(I18n.t("authentication.profiles.edit.edit_preferences_title"))
      end

      it "shows the edit preferences link" do
        expect(response.body).to include(profile_shelter_onboarding_path(from_profile: true))
      end

      it "shows the shelter information section" do
        expect(response.body).to include(I18n.t("authentication.profiles.edit.shelter_info_title"))
      end

      it "shows the edit shelter info link" do
        expect(response.body).to include(edit_shelter_path(id: user.shelter_id))
      end
    end

    context "as a shelter user without a shelter" do
      let(:user) { create(:user, :verified, :onboarding_completed, :shelter_admin, shelter: nil) }

      before do
        post session_path, params: { session: { email: user.email, password: "password123" } }
        get edit_profile_path
      end

      it "does not show the shelter information section" do
        expect(response.body).not_to include(I18n.t("authentication.profiles.edit.shelter_info_title"))
      end
    end
  end
end

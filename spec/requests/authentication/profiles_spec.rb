require "rails_helper"

RSpec.describe "Profiles" do
  describe "GET /profile/edit" do
    it "redirects to login when not authenticated" do
      get edit_profile_path
      expect(response).to redirect_to(new_session_path)
    end

    it "renders the edit form when logged in" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get edit_profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("authentication.profiles.edit.title"))
    end

    it "renders the email as read-only (not an editable field)" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get edit_profile_path
      expect(response.body).to include(user.email)
      expect(response.body).not_to include('name="user[email]"')
      expect(response.body).to include(CGI.escapeHTML(I18n.t("authentication.profiles.edit.email_readonly_hint")))
    end

    it "renders the adoption journey strip for individual users" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get edit_profile_path
      expect(response.body).to include(I18n.t("authentication.profiles.edit.journey.title"))
      expect(response.body).to include(I18n.t("authentication.profiles.edit.journey.milestone.profile_starter"))
    end
  end

  describe "PATCH /profile" do
    it "redirects to login when not authenticated" do
      patch profile_path, params: { user: { name: "New Name" } }
      expect(response).to redirect_to(new_session_path)
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

      context "when attempting to change the email (read-only field)" do
        let(:new_email) { "newemail@example.com" }

        it "ignores the submitted email and keeps the account email unchanged" do
          patch profile_path, params: { user: { name: user.name, email: new_email } }
          expect(user.reload.email).to eq(user.email)
          expect(user.reload.email).not_to eq(new_email)
        end

        it "does not mark the account unverified" do
          patch profile_path, params: { user: { name: user.name, email: new_email } }
          expect(user.reload).to be_verified
        end

        it "does not send a verification email" do
          expect { patch profile_path, params: { user: { name: user.name, email: new_email } } }
            .not_to have_enqueued_mail(AuthenticationMailer, :verification)
        end
      end

      context "with invalid data" do
        it "re-renders the form with errors" do
          patch profile_path, params: { user: { name: "", email: user.email } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when saving only the locale (language selector auto-save)" do
        it "persists the locale without clearing name or email" do
          patch profile_path, params: { user: { locale: "es" } }
          expect(response).to redirect_to(edit_profile_path)
          user.reload
          expect(user.locale).to eq("es")
          expect(user.name).to be_present
          expect(user.email).to be_present
        end

        it "does not change the email or mark it unverified" do
          original_email = user.email
          patch profile_path, params: { user: { locale: "en" } }
          user.reload
          expect(user.email).to eq(original_email)
          expect(user).to be_verified
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

    context "as shelter staff with a shelter" do
      let(:shelter) { create(:shelter) }
      let(:user) { create(:user, :verified, :onboarding_completed, :shelter_staff, shelter: shelter) }

      before do
        post session_path, params: { session: { email: user.email, password: "password123" } }
        get edit_profile_path
      end

      it "does not show the shelter information section" do
        expect(response.body).not_to include(I18n.t("authentication.profiles.edit.shelter_info_title"))
      end

      # Reproduces Bug 2.1a: before the fix staff were shown an "Edit Shelter
      # Information" link that always redirected them as unauthorized.
      it "does not show the edit shelter info link" do
        expect(response.body).not_to include(edit_shelter_path(id: user.shelter_id))
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

  describe "Verified badge (UI refinement 4.1)" do
    before do
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get edit_profile_path
    end

    context "when the account is verified" do
      let(:user) { create(:user, :verified, :onboarding_completed) }

      it "renders a squared verified badge (not a pill)" do
        expect(response.body).to include("rounded-lg bg-success/10 text-success")
        expect(response.body).not_to include("rounded-full bg-success/10")
      end

      it "places the verified badge in the card header before the account form" do
        badge_index = response.body.index('aria-label="Verified"')
        form_index = response.body.index('class="space-y-5"')
        expect(badge_index).to be_present
        expect(form_index).to be_present
        expect(badge_index).to be < form_index
      end

      it "marks the badge as a live status region" do
        expect(response.body).to include('role="status"')
      end
    end

    context "when the account is pending verification" do
      # Unverified users cannot log in, so sign in first, then unverify.
      let(:user) { create(:user, :verified, :onboarding_completed) }

      before do
        user.update!(verified_at: nil)
        get edit_profile_path
      end

      it "renders a squared pending badge (not a pill)" do
        expect(response.body).to include("rounded-lg bg-warning/10 text-warning")
        expect(response.body).not_to include("rounded-full bg-warning/10")
      end
    end
  end

  describe "Language selector (UI refinement 4.2)" do
    let(:user) { create(:user, :verified, :onboarding_completed) }

    before do
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get edit_profile_path
    end

    # Locks the progressive-enhancement contract: without JS the page must
    # still work through the native <select> + Save button, and the custom
    # control must start hidden and only be revealed by the Stimulus
    # controller (language_select_controller.js#upgrade).
    context "no-JS fallback" do
      it "keeps the native select as the source of truth with both options" do
        expect(response.body).to include('name="user[locale]"')
        expect(response.body).to include('<option selected="selected" value="en">')
        expect(response.body).to include('<option value="es">')
      end

      it "pre-selects the current locale in the native select" do
        expect(response.body).to include('<option selected="selected" value="en">')
        expect(response.body).not_to include('<option selected="selected" value="es">')
      end

      it "keeps the explicit save button for the no-JS path" do
        expect(response.body).to include(I18n.t("authentication.profiles.edit.language_save"))
      end

      it "renders the custom control hidden until JS upgrades it" do
        expect(response.body).to include('class="hidden" data-language-select-target="control"')
      end

      it "renders the full custom control markup for the JS path" do
        expect(response.body).to include('role="combobox"')
        expect(response.body).to include('aria-expanded="false"')
        expect(response.body).to include('role="listbox"')
        expect(response.body).to include('role="option"')
      end
    end

    context "when the user's locale is Spanish" do
      let(:user) { create(:user, :verified, :onboarding_completed, locale: "es") }

      it "pre-selects Spanish in both the native select and the custom control" do
        expect(response.body).to include('<option selected="selected" value="es">')
        expect(response.body).to include('id="language-option-es"')
        expect(response.body).to include('data-value="es"')
        expect(response.body).to include('aria-selected="true"')
      end
    end
  end
end

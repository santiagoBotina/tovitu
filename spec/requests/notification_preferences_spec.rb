require "rails_helper"

RSpec.describe "NotificationPreferences" do
  let(:user) { create(:user, :verified) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /notification_preferences/edit" do
    it "returns a successful response" do
      get edit_notification_preferences_path
      expect(response).to have_http_status(:ok)
    end

    it "creates default preferences if none exist" do
      user.notification_preference&.destroy!
      user.reload
      get edit_notification_preferences_path
      expect(user.reload.notification_preference).to be_present
    end

    it "renders i18n'd copy instead of hardcoded strings (AC-7.1-6)" do
      get edit_notification_preferences_path
      expect(response.body).to include(I18n.t("notifications.preferences.in_app_desc"))
      expect(response.body).to include(I18n.t("notifications.preferences.email_desc"))
    end

    it "renders Spanish copy when the user's locale is Spanish" do
      user.update!(locale: "es")
      get edit_notification_preferences_path(locale: :es)
      expect(response.body).to include(I18n.t("notifications.preferences.in_app_desc", locale: :es))
      expect(response.body).to include(I18n.t("notifications.preferences.per_kind_title", locale: :es))
    end

    it "renders per-kind email toggles for triggerable kinds (AC-7.1-5)" do
      get edit_notification_preferences_path
      NotificationPreference.ui_kinds.each do |kind|
        expect(response.body).to include("notification_preference[per_kind_overrides][#{kind}][email]")
      end
    end

    it "shows the per-kind section when email is on and hides it when off (preserves overrides)" do
      get edit_notification_preferences_path
      container = response.body[/data-preference-kind-toggle-target="kinds"/]
      expect(container).to be_present
      NotificationPreference.defaults_for(user).update!(email: false)
      get edit_notification_preferences_path
      expect(response.body).to match(/mt-4 space-y-3 hidden" data-preference-kind-toggle-target="kinds"/)
    end

    it "does not render toggles for deferred kinds" do
      get edit_notification_preferences_path
      expect(response.body).not_to include("notification_preference[per_kind_overrides][message_received]")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to root" do
        get edit_notification_preferences_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "with a verified WhatsApp number" do
      let!(:preference) { create(:notification_preference, :whatsapp_opted_in, user: user) }

      it "shows the shared squared verified badge (UI refinement 4.1)" do
        get edit_notification_preferences_path
        expect(response.body).to include("rounded-lg bg-success/10 text-success")
        expect(response.body).not_to include("text-secondary-600 bg-secondary-50")
      end
    end
  end

  describe "PATCH /notification_preferences" do
    let(:valid_params) do
      {
        notification_preference: {
          in_app: true,
          email: false,
          whatsapp: true,
          whatsapp_phone: "+15551234567"
        }
      }
    end

    it "updates the notification preferences" do
      patch notification_preferences_path, params: valid_params
      expect(user.reload.notification_preference.email).to be false
      expect(user.reload.notification_preference.whatsapp).to be true
    end

    it "redirects with a success notice" do
      patch notification_preferences_path, params: valid_params
      expect(response).to redirect_to(edit_notification_preferences_path)
    end

    it "creates a preference if one doesn't exist" do
      user.notification_preference&.destroy!
      user.reload
      expect {
        patch notification_preferences_path, params: valid_params
      }.to change(NotificationPreference, :count).by(1)
    end

    it "re-renders the form with errors on invalid data" do
      patch notification_preferences_path, params: { notification_preference: { in_app: nil } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    describe "per-kind email toggles (AC-7.1-5)" do
      it "stores per-kind overrides from checkbox params" do
        params = {
          notification_preference: {
            email: true,
            per_kind_overrides: {
              "request_submitted" => { "email" => "false" },
              "welcome" => { "email" => "true" }
            }
          }
        }
        patch notification_preferences_path, params: params
        prefs = user.reload.notification_preference
        expect(prefs.kind_enabled?(:request_submitted, :email)).to be false
        expect(prefs.kind_enabled?(:welcome, :email)).to be true
      end

      it "global email OFF wins even when a per-kind override would enable it" do
        params = {
          notification_preference: {
            email: false,
            per_kind_overrides: {
              "request_accepted" => { "email" => "true" }
            }
          }
        }
        patch notification_preferences_path, params: params
        prefs = user.reload.notification_preference
        expect(prefs.email).to be false
        expect(prefs.kind_enabled?(:request_accepted, :email)).to be false
      end

      it "does not wipe per-kind mutes when the global toggle is turned off (hidden section submits nothing)" do
        NotificationPreference.defaults_for(user).update!(
          email: true,
          per_kind_overrides: { "request_accepted" => { "email" => false } }
        )
        patch notification_preferences_path, params: { notification_preference: { email: false } }
        prefs = user.reload.notification_preference
        expect(prefs.per_kind_enabled?(:request_accepted, :email)).to be false
        # Re-enabling global email restores the original mute, not a full reset
        patch notification_preferences_path, params: { notification_preference: { email: true } }
        expect(user.reload.notification_preference.kind_enabled?(:request_accepted, :email)).to be false
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to root" do
        patch notification_preferences_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end
end

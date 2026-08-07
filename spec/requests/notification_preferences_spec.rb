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

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to root" do
        patch notification_preferences_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end
end

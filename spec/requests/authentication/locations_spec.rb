require "rails_helper"

# Request specs for the profile-settings "My Location" management
# (REQ-48-4 / AC-48-4, AC-48-5): view, update (device re-detection / manual
# edit), and delete, plus the authorization boundary (adopter-only, own record
# only).
RSpec.describe "Profile location settings", type: :request do
  let(:user) { create(:user, :verified, :onboarding_completed) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "PATCH /profile/location" do
    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to login" do
        patch profile_location_path, params: { intent: "manual", city: "Austin" }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "as a shelter account" do
      let(:shelter) { create(:shelter) }
      let(:user) { create(:user, :verified, :shelter_admin, shelter: shelter) }

      it "is unauthorized and does not create a location" do
        patch profile_location_path, params: { intent: "manual", city: "Austin" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.unauthorized"))
        expect(user.reload.user_location).to be_nil
      end
    end

    context "as an individual with no location" do
      it "creates a manual location and records consent" do
        patch profile_location_path,
              params: { intent: "manual", city: "Austin", region: "TX", country: "United States" }

        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:notice]).to eq(I18n.t("locations.flash.updated"))

        location = user.reload.user_location
        expect(location).to be_present
        expect(location.source).to eq("manual")
        expect(location).to be_manual
        expect(location.city).to eq("Austin")
        expect(location.region).to eq("TX")
        expect(location.country).to eq("United States")
        expect(location.latitude).to be_nil
        expect(location.longitude).to be_nil

        expect(user.location_decision).to eq("shared")
        expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
        expect(user.location_decision_at).to be_present
      end
    end

    context "as an individual with an existing location" do
      let!(:location) { create(:user_location, user: user, city: "Old City", source: "manual") }
      let!(:decision_at) { 3.days.ago }

      before do
        user.update!(
          location_decision: "shared",
          location_disclosure_version: Locations::DISCLOSURE_VERSION,
          location_decision_at: decision_at
        )
      end

      it "re-detects from the device and updates the location without re-recording consent" do
        allow(Locations::ReverseGeocode).to receive(:call)
          .and_return(Result.success(Locations::Place.new(city: "Austin", region: "TX", country: "United States")))

        patch profile_location_path,
              params: { intent: "device", latitude: "30.267153", longitude: "-97.7431" }

        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:notice]).to eq(I18n.t("locations.flash.updated"))

        location.reload
        expect(location.source).to eq("device")
        expect(location).to be_device
        expect(location.city).to eq("Austin")
        expect(location.region).to eq("TX")
        expect(location.latitude.to_f).to eq(30.27)
        expect(location.longitude.to_f).to eq(-97.74)

        user.reload
        expect(user.location_decision).to eq("shared")
        expect(user.location_decision_at).to eq(decision_at)
      end

      it "edits the city manually without re-recording consent" do
        patch profile_location_path,
              params: { intent: "manual", city: "Round Rock", region: "TX" }

        expect(response).to redirect_to(edit_profile_path)

        location.reload
        expect(location.city).to eq("Round Rock")
        expect(location.source).to eq("manual")
        expect(user.reload.location_decision_at).to eq(decision_at)
      end
    end

    context "when an individual tries to act on another user's record" do
      let(:other_user) { create(:user, :verified, :onboarding_completed) }
      let!(:other_location) { create(:user_location, user: other_user, city: "Original City", source: "manual") }

      it "only ever touches the current user's own location (forged user_id is ignored)" do
        patch profile_location_path,
              params: { intent: "manual", city: "Hacked City", user_id: other_user.id }

        expect(other_user.reload.user_location.city).to eq("Original City")
        expect(user.reload.user_location.city).to eq("Hacked City")
      end
    end
  end

  describe "DELETE /profile/location" do
    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to login" do
        delete profile_location_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "as an individual with a location" do
      let!(:location) { create(:user_location, user: user, city: "Austin", source: "manual") }

      before do
        user.update!(
          location_decision: "shared",
          location_disclosure_version: Locations::DISCLOSURE_VERSION,
          location_decision_at: Time.current
        )
      end

      it "removes the location but keeps the consent record" do
        delete profile_location_path

        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:notice]).to eq(I18n.t("locations.flash.deleted"))
        expect(user.reload.user_location).to be_nil
        expect(user.location_decision).to eq("shared")
        expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
        expect(user.location_decision_at).to be_present
      end
    end
  end

  describe "GET /profile/edit" do
    context "as an individual with a location" do
      let!(:location) { create(:user_location, user: user, city: "Austin", region: "TX", source: "manual") }

      it "renders the My Location card showing the city, source, and last-updated" do
        get edit_profile_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="my-location-card"')
        expect(response.body).to include(I18n.t("locations.settings.title"))
        expect(response.body).to include("Austin")
        expect(response.body).to include(I18n.t("locations.manual"))
        expect(response.body).to include(I18n.t("locations.settings.update_to_current"))
        expect(response.body).to include(I18n.t("locations.settings.delete"))
        expect(response.body).to include("city-autocomplete")
        expect(response.body).to include("city-listbox-settings")
        expect(response.body).to include('value="Austin"')
      end
    end

    context "as an individual without a location" do
      it "renders the My Location card with the add-location offer" do
        get edit_profile_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="my-location-card"')
        expect(response.body).to include(I18n.t("locations.settings.add_title"))
        expect(response.body).to include(I18n.t("locations.settings.use_current_location"))
        expect(response.body).to include(I18n.t("locations.settings.enter_manually"))
        expect(response.body).to include(I18n.t("locations.settings.not_now"))
      end
    end
  end
end

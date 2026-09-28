require "rails_helper"

# Request specs for the optional location step (question 9) in the individual
# onboarding wizard (REQ-48-1, REQ-48-2, REQ-48-3, REQ-48-4, REQ-48-9).
#
# The step accepts three intents over the JSON PATCH contract:
#   device — reverse-geocodes browser coords to city-level precision
#   manual — stores the typed city/region/country
#   skip   — records the consent decision (skipped) with no location
RSpec.describe "Onboarding location step", type: :request do
  let(:user) { create(:user, :verified) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  def patch_location(params)
    patch onboarding_individual_location_path,
          params: params.to_json,
          headers: { "Content-Type" => "application/json" }
  end

  describe "GET /onboarding/individual/questions" do
    it "renders the location step (step 9) with the purpose disclosure" do
      get onboarding_individual_questions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-type="location"')
      expect(response.body).to include(I18n.t("locations.disclosure"))
      expect(response.body).to include(I18n.t("locations.onboarding.use_current_location"))
      expect(response.body).to include(I18n.t("locations.onboarding.enter_manually"))
      expect(response.body).to include(I18n.t("locations.onboarding.skip_for_now"))
      expect(response.body).to include("city-autocomplete")
      expect(response.body).to include("city-listbox-onboarding")
    end
  end

  describe "PATCH /onboarding/individual/location" do
    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to login" do
        patch_location(intent: "skip")
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the account is a shelter user" do
      let(:shelter) { create(:shelter) }
      let(:user) { create(:user, :verified, :shelter_admin, shelter: shelter) }

      it "returns 403 with a JSON error (adopter-only feature)" do
        patch_location(intent: "skip")

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to eq(
          "success" => false,
          "errors" => [ I18n.t("flash.unauthorized") ]
        )
      end
    end

    context "with intent device" do
      before do
        allow(Locations::ReverseGeocode).to receive(:call)
          .and_return(Result.success(Locations::Place.new(city: "Austin", region: "TX", country: "United States")))
      end

      it "stores a device-sourced location at city-level precision and records consent" do
        patch_location(intent: "device", latitude: "30.267153", longitude: "-97.7431")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("success" => true)

        location = user.reload.user_location
        expect(location).to be_present
        expect(location.source).to eq("device")
        expect(location).to be_device
        expect(location.city).to eq("Austin")
        expect(location.region).to eq("TX")
        expect(location.country).to eq("United States")
        # Full device precision is never persisted (AC-48-3): reduced to 2 decimals.
        expect(location.latitude.to_f).to eq(30.27)
        expect(location.longitude.to_f).to eq(-97.74)

        expect(user.location_decision).to eq("shared")
        expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
        expect(user.location_decision_at).to be_present
      end

      it "never persists the full device precision" do
        patch_location(intent: "device", latitude: "30.267153", longitude: "-97.7431")

        location = user.reload.user_location
        expect(location.latitude.to_s).not_to eq("30.267153")
        expect(location.longitude.to_s).not_to eq("-97.7431")
      end

      context "when coordinates are missing" do
        it "returns 422 with a localized error" do
          patch_location(intent: "device")

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["success"]).to be(false)
          expect(response.parsed_body["errors"]).to include(I18n.t("locations.errors.coordinates_required"))
        end
      end

      context "when reverse geocoding fails" do
        before do
          allow(Locations::ReverseGeocode).to receive(:call)
            .and_return(Result.failure([ I18n.t("locations.errors.reverse_geocode_failed") ]))
        end

        it "returns 422 with the reverse-geocode error (graceful degradation)" do
          patch_location(intent: "device", latitude: "30.267153", longitude: "-97.7431")

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["success"]).to be(false)
          expect(response.parsed_body["errors"]).to include(I18n.t("locations.errors.reverse_geocode_failed"))
        end
      end
    end

    context "with intent manual" do
      it "stores a manual location with nil coordinates and records consent" do
        patch_location(intent: "manual", city: "Austin", region: "TX", country: "United States")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("success" => true)

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

      context "when city is missing" do
        it "returns 422 with a localized error" do
          patch_location(intent: "manual", city: "")

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["errors"]).to include(I18n.t("locations.errors.city_required"))
        end
      end
    end

    context "with intent skip" do
      it "records the skipped decision without creating a location" do
        patch_location(intent: "skip")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("success" => true)

        expect(user.reload.user_location).to be_nil
        expect(user.location_decision).to eq("skipped")
        expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
        expect(user.location_decision_at).to be_present
      end
    end

    context "with an invalid intent" do
      it "returns 422 with a localized error" do
        patch_location(intent: "teleport")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["success"]).to be(false)
        expect(response.parsed_body["errors"]).to include(I18n.t("locations.errors.invalid_intent"))
      end
    end

    context "when consent was already recorded for the same purpose" do
      it "does not overwrite the original consent timestamp on a same-purpose update (REQ-48-4)" do
        allow(Locations::ReverseGeocode).to receive(:call)
          .and_return(Result.success(Locations::Place.new(city: "Austin", region: "TX", country: "United States")))

        patch_location(intent: "device", latitude: "30.267153", longitude: "-97.7431")
        original_decision_at = user.reload.location_decision_at

        travel 1.day do
          patch_location(intent: "manual", city: "Round Rock", region: "TX", country: "United States")
        end

        user.reload
        expect(user.user_location.city).to eq("Round Rock")
        expect(user.location_decision).to eq("shared")
        expect(user.location_decision_at).to eq(original_decision_at)
      end
    end
  end

  describe "onboarding completion without a location decision" do
    it "completes onboarding when the location step is skipped (never blocked)" do
      answers = {
        1 => %w[going_for_walks],
        2 => "active",
        3 => "playful_companion",
        4 => "some_experience",
        5 => %w[daily_companion],
        6 => "2_to_4h",
        7 => "adventurous_energetic",
        8 => "A loving home"
      }
      answers.each do |qnum, answer|
        patch onboarding_individual_questions_path,
              params: { question_number: qnum, answer: answer }.to_json,
              headers: { "Content-Type" => "application/json" }
      end

      post onboarding_individual_completion_path, params: { skip: "false" }

      expect(response).to redirect_to("/en/pets")
      expect(user.reload).to be_onboarding_completed
      expect(user.user_location).to be_nil
    end
  end
end

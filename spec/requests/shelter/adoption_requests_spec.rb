require "rails_helper"

# Shelter-facing privacy boundary for adopter location (REQ-48-5, REQ-48-6,
# AC-48-5, AC-48-6, AC-48-7, AC-48-8): shelters see only the adopter's city —
# never coordinates — and the submission-time city snapshot survives later
# deletion.
RSpec.describe "Shelter adoption requests (location privacy)", type: :request do
  let(:shelter) { create(:shelter) }
  let(:staff) { create(:user, :verified, :shelter_admin, shelter: shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }

  before do
    # Adopters who apply have completed onboarding, which creates their
    # individual profile. The shelter show renders the City row inside the
    # profile section, so the profile must exist for the row to appear.
    create(:individual_profile, user: adopter)
    post session_path, params: { session: { email: staff.email, password: "password123" } }
  end

  describe "GET /shelter/adoption_requests/:id" do
    context "when the adopter has a location" do
      let!(:location) do
        create(:user_location,
               user: adopter,
               city: "Austin",
               region: "TX",
               country: "United States",
               latitude: 30.267153,
               longitude: -97.7431,
               source: "device")
      end
      let!(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter) }

      it "shows the adopter's city" do
        get shelter_adoption_request_path(request)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Austin")
      end

      it "never renders the adopter's coordinates" do
        get shelter_adoption_request_path(request)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("30.267153")
        expect(response.body).not_to include("-97.7431")
      end
    end

    context "when the adopter has no location" do
      let!(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter) }

      it "shows the neutral localized 'City not shared' state" do
        get shelter_adoption_request_path(request)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("locations.not_shared"))
      end
    end

    context "when the adopter deletes their location after applying" do
      it "still shows the submission-time city snapshot (REQ-48-6)" do
        create(:user_location, user: adopter, city: "Austin", region: "TX", source: "device")

        result = Adoptions::SubmitRequest.call(adopter: adopter, pet: pet)
        expect(result).to be_success
        request = result.data
        expect(request.adopter_city).to eq("Austin")

        adopter.user_location.destroy!

        get shelter_adoption_request_path(request)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Austin")
        expect(response.body).not_to include(I18n.t("locations.not_shared"))
      end
    end
  end
end

require "rails_helper"

RSpec.describe "Shelter Policies" do
  let(:shelter) { create(:shelter) }
  let(:admin) { create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter) }

  before do
    post session_path, params: { session: { email: admin.email, password: "password123" } }
  end

  describe "GET /shelters/:shelter_id/policies/edit" do
    it "renders the edit form" do
      get edit_shelter_policies_path(shelter_id: shelter)
      expect(response).to have_http_status(:ok)
    end

    it "rejects non-admin access" do
      staff = create(:user, :verified, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      get edit_shelter_policies_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /shelters/:shelter_id/policies" do
    it "updates adoption policies" do
      patch shelter_policies_path(shelter_id: shelter), params: {
        shelter: {
          adoption_policies: {
            adoption_fee: 150,
            fee_description: "Standard adoption fee",
            minimum_age: 21,
            home_visit_required: true,
            fenced_yard_required: false,
            vet_reference_required: true
          }
        }
      }

      expect(response).to redirect_to(edit_shelter_policies_path(shelter_id: shelter))
      expect(shelter.reload.adoption_policies["adoption_fee"]).to eq("150")
      expect(shelter.reload.adoption_policies["home_visit_required"]).to eq("true")
    end

    it "rejects non-admin updates" do
      staff = create(:user, :verified, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      patch shelter_policies_path(shelter_id: shelter), params: {
        shelter: { adoption_policies: { adoption_fee: 200 } }
      }
      expect(response).to redirect_to(root_path)
    end
  end
end

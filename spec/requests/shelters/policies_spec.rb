require "rails_helper"

RSpec.describe "Shelter Policies" do
  let(:shelter) { create(:shelter) }
  let(:admin) { create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter) }

  before do
    post session_path, params: { session: { email: admin.email, password: "password123" } }
  end

  describe "GET /shelters/:shelter_id/policies" do
    it "requires authentication" do
      delete session_path

      get shelter_policies_path(shelter_id: shelter)
      expect(response).to redirect_to(new_session_path)
    end

    it "renders the read-only policies page for the shelter admin" do
      get shelter_policies_path(shelter_id: shelter)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("shelters.policies.show.title"))
    end

    it "rejects non-admin access" do
      staff = create(:user, :verified, :shelter_staff, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      get shelter_policies_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.unauthorized"))
    end

    it "rejects admins of another shelter" do
      other = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: create(:shelter))
      delete session_path
      post session_path, params: { session: { email: other.email, password: "password123" } }

      get shelter_policies_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.unauthorized"))
    end
  end

  describe "GET /shelters/:shelter_id/policies/edit" do
    it "renders the edit form" do
      get edit_shelter_policies_path(shelter_id: shelter)
      expect(response).to have_http_status(:ok)
    end

    it "rejects non-admin access" do
      staff = create(:user, :verified, :shelter_staff, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      get edit_shelter_policies_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.unauthorized"))
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

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
      expect(shelter.reload.adoption_policies["adoption_fee"]).to eq("150")
      expect(shelter.reload.adoption_policies["home_visit_required"]).to eq("true")
    end

    # Regression guard for AC-42-6: the restyled edit form must still submit the
    # full fixed policy set under shelter[adoption_policies][...] and persist it.
    it "persists the full policy set including other_requirements" do
      patch shelter_policies_path(shelter_id: shelter), params: {
        shelter: {
          adoption_policies: {
            adoption_fee: 150,
            fee_description: "Standard adoption fee",
            minimum_age: 21,
            home_visit_required: true,
            fenced_yard_required: false,
            vet_reference_required: true,
            other_requirements: "Must live within 50 miles\nMust have previous pet experience"
          }
        }
      }

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
      policies = shelter.reload.adoption_policies
      expect(policies["adoption_fee"]).to eq("150")
      expect(policies["fee_description"]).to eq("Standard adoption fee")
      expect(policies["minimum_age"]).to eq("21")
      expect(policies["home_visit_required"]).to eq("true")
      expect(policies["fenced_yard_required"]).to eq("false")
      expect(policies["vet_reference_required"]).to eq("true")
      expect(policies["other_requirements"]).to eq("Must live within 50 miles\nMust have previous pet experience")
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

require "rails_helper"

RSpec.describe "Shelter Dashboard" do
  describe "GET /shelters/:shelter_id/dashboard" do
    it "requires authentication" do
      shelter = create(:shelter)
      get shelter_dashboard_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
    end

    it "shows dashboard to shelter members" do
      shelter = create(:shelter)
      user = create(:user, :verified, :onboarding_completed, shelter: shelter)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      get shelter_dashboard_path(shelter_id: shelter)
      expect(response).to have_http_status(:ok)
    end

    it "rejects non-members" do
      shelter = create(:shelter)
      user = create(:user, :verified)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      get shelter_dashboard_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "admin-only shelter settings links" do
    let(:shelter) { create(:shelter) }

    # Ensures the welcome overlay (rendered only when the shelter has no pets)
    # does not interfere with the dashboard body.
    before { create(:pet, shelter: shelter) }

    context "as the shelter admin" do
      let(:admin) { create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter) }

      before do
        post session_path, params: { session: { email: admin.email, password: "password123" } }
        get shelter_dashboard_path(shelter_id: shelter)
      end

      it "renders the Manage Team quick action" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("shelters.dashboard.show.quick_actions.manage_team.title"))
      end

      it "renders the Adoption Policies quick action" do
        expect(response.body).to include(I18n.t("shelters.dashboard.show.quick_actions.policies.title"))
      end
    end

    context "as shelter staff" do
      let(:staff) { create(:user, :verified, :shelter_staff, :onboarding_completed, shelter: shelter) }

      before do
        post session_path, params: { session: { email: staff.email, password: "password123" } }
        get shelter_dashboard_path(shelter_id: shelter)
      end

      it "renders the dashboard without a 500" do
        expect(response).to have_http_status(:ok)
      end

      # Reproduces Bug 2.1a: before the fix the dashboard presented admin-only
      # edit links to staff, who were then redirected with "not authorized".
      it "does not render the Manage Team quick action" do
        expect(response.body).not_to include(I18n.t("shelters.dashboard.show.quick_actions.manage_team.title"))
        expect(response.body).not_to include(shelter_staff_index_path(shelter_id: shelter))
      end

      it "does not render the Adoption Policies quick action" do
        expect(response.body).not_to include(I18n.t("shelters.dashboard.show.quick_actions.policies.title"))
        expect(response.body).not_to include(edit_shelter_policies_path(shelter_id: shelter))
      end
    end
  end
end

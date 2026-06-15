require "rails_helper"

RSpec.describe "Shelter Dashboard" do
  describe "GET /shelters/:shelter_id/dashboard" do
    it "requires authentication" do
      shelter = create(:shelter)
      get shelter_dashboard_path(shelter_id: shelter)
      expect(response).to redirect_to(new_session_path)
    end

    it "shows dashboard to shelter members" do
      shelter = create(:shelter)
      user = create(:user, :verified, shelter: shelter)
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
end

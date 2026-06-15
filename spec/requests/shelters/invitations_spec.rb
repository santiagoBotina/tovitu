require "rails_helper"

RSpec.describe "Shelter Invitations" do
  let(:shelter) { create(:shelter) }
  let(:admin) { create(:user, :verified, :admin, :onboarding_completed, shelter: shelter) }

  describe "POST /shelters/:shelter_id/invitations" do
    it "accepts a valid invitation" do
      invitation = create(:invitation, shelter: shelter, created_by: admin)
      user = create(:user, :verified, :onboarding_completed)

      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelter_invitations_path(shelter_id: shelter), params: { token: invitation.token }

      expect(response).to redirect_to(shelter_dashboard_path(shelter_id: shelter))
      expect(user.reload.shelter).to eq(shelter)
      expect(invitation.reload.accepted?).to be true
    end

    it "rejects expired invitations" do
      invitation = create(:invitation, :expired, shelter: shelter, created_by: admin)
      user = create(:user, :verified)

      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelter_invitations_path(shelter_id: shelter), params: { token: invitation.token }

      expect(response).to redirect_to(root_path)
      expect(user.reload.shelter).to be_nil
    end

    it "rejects already accepted invitations" do
      invitation = create(:invitation, :accepted, shelter: shelter, created_by: admin)
      user = create(:user, :verified)

      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelter_invitations_path(shelter_id: shelter), params: { token: invitation.token }

      expect(response).to redirect_to(root_path)
      expect(user.reload.shelter).to be_nil
    end

    it "rejects invalid tokens" do
      user = create(:user, :verified)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelter_invitations_path(shelter_id: shelter), params: { token: "invalid_token" }

      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      post shelter_invitations_path(shelter_id: shelter), params: { token: "anything" }
      expect(response).to redirect_to(root_path)
    end
  end
end

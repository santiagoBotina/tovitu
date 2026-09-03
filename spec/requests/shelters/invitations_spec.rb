require "rails_helper"

RSpec.describe "Shelter Invitations" do
  let(:shelter) { create(:shelter) }
  let(:owner) { create(:user, :verified, :shelter_owner, :onboarding_completed, shelter: shelter) }

  describe "POST /shelters/:shelter_id/invitations" do
    it "accepts a valid invitation and applies the stored role" do
      user = create(:user, :verified, :onboarding_completed)
      invitation = create(:invitation, role: "administrator", shelter: shelter, created_by: owner, email: user.email)

      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelter_invitations_path(shelter_id: shelter), params: { token: invitation.token }

      expect(response).to redirect_to(shelter_dashboard_path(shelter_id: shelter))
      expect(user.reload.shelter).to eq(shelter)
      expect(user.reload.shelter_role).to eq("administrator")
      expect(invitation.reload.accepted?).to be true
    end

    it "rejects expired invitations" do
      invitation = create(:invitation, :expired, shelter: shelter, created_by: owner)
      user = create(:user, :verified)

      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelter_invitations_path(shelter_id: shelter), params: { token: invitation.token }

      expect(response).to redirect_to(root_path)
      expect(user.reload.shelter).to be_nil
    end

    it "rejects already accepted invitations" do
      invitation = create(:invitation, :accepted, shelter: shelter, created_by: owner)
      user = create(:user, :verified)

      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelter_invitations_path(shelter_id: shelter), params: { token: invitation.token }

      expect(response).to redirect_to(root_path)
      expect(user.reload.shelter).to be_nil
    end

    it "rejects cancelled invitations" do
      invitation = create(:invitation, :cancelled, shelter: shelter, created_by: owner)
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
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "DELETE /shelters/:shelter_id/invitations/:id/cancel" do
    it "cancels a pending invitation as the owner" do
      invitation = create(:invitation, shelter: shelter, created_by: owner)
      post session_path, params: { session: { email: owner.email, password: "password123" } }

      delete cancel_shelter_invitation_path(shelter_id: shelter, id: invitation)
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(invitation.reload).to be_cancelled
    end

    it "rejects cancellation by a non-owner" do
      administrator = create(:user, :verified, :shelter_administrator, :onboarding_completed, shelter: shelter)
      invitation = create(:invitation, shelter: shelter, created_by: owner)
      post session_path, params: { session: { email: administrator.email, password: "password123" } }

      delete cancel_shelter_invitation_path(shelter_id: shelter, id: invitation)
      expect(response).to redirect_to(root_path)
      expect(invitation.reload.cancelled?).to be false
    end

    it "requires authentication" do
      invitation = create(:invitation, shelter: shelter, created_by: owner)
      delete cancel_shelter_invitation_path(shelter_id: shelter, id: invitation)
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "cross-shelter protection" do
    let(:shelter_b) { create(:shelter) }
    let(:owner_b) { create(:user, :verified, :shelter_owner, :onboarding_completed, shelter: shelter_b) }

    it "blocks the owner from cancelling another shelter's invitation" do
      invitation = create(:invitation, shelter: shelter_b, created_by: owner_b)
      post session_path, params: { session: { email: owner.email, password: "password123" } }

      delete cancel_shelter_invitation_path(shelter_id: shelter_b, id: invitation)
      expect(response).to redirect_to(root_path)
      expect(invitation.reload.cancelled?).to be false
    end
  end
end

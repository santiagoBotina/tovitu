require "rails_helper"

RSpec.describe "Shelter Staff" do
  let(:shelter) { create(:shelter) }
  let(:owner) { create(:user, :verified, :shelter_owner, :onboarding_completed, shelter: shelter) }

  before do
    post session_path, params: { session: { email: owner.email, password: "password123" } }
  end

  describe "GET /shelters/:shelter_id/staff" do
    it "lists staff members" do
      staff = create(:user, :verified, :onboarding_completed, :shelter_staff_member, shelter: shelter)
      get shelter_staff_index_path(shelter_id: shelter)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(staff.name)
    end

    it "rejects staff_member access" do
      staff = create(:user, :verified, :shelter_staff_member, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      get shelter_staff_index_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.unauthorized"))
    end

    it "allows an administrator to view the staff list" do
      administrator = create(:user, :verified, :shelter_administrator, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: administrator.email, password: "password123" } }

      get shelter_staff_index_path(shelter_id: shelter)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /shelters/:shelter_id/staff" do
    it "invites a new staff member with a role" do
      expect do
        post shelter_staff_index_path(shelter_id: shelter), params: { email: "newstaff@example.com", role: "staff_member" }
      end.to change(Invitation, :count).by(1)

      expect(Invitation.last.role).to eq("staff_member")
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
    end

    it "requires a role before sending an invitation" do
      expect do
        post shelter_staff_index_path(shelter_id: shelter), params: { email: "newstaff@example.com" }
      end.not_to change(Invitation, :count)

      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
    end

    it "no longer auto-adds existing users without a shelter" do
      existing = create(:user, :verified, email: "existing@example.com")
      expect do
        post shelter_staff_index_path(shelter_id: shelter), params: { email: "existing@example.com", role: "staff_member" }
      end.to change(Invitation, :count).by(1)

      expect(existing.reload.shelter_id).to be_nil
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
    end

    it "rejects if email is already a member" do
      existing = create(:user, :verified, :onboarding_completed, :shelter_staff_member, shelter: shelter)
      post shelter_staff_index_path(shelter_id: shelter), params: { email: existing.email, role: "staff_member" }
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(flash[:alert]).to be_present
    end

    it "rejects invitations from a non-owner" do
      administrator = create(:user, :verified, :shelter_administrator, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: administrator.email, password: "password123" } }

      expect do
        post shelter_staff_index_path(shelter_id: shelter), params: { email: "newstaff@example.com", role: "staff_member" }
      end.not_to change(Invitation, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /shelters/:shelter_id/staff/:id/change_role" do
    it "changes a staff member's role" do
      staff = create(:user, :verified, :onboarding_completed, :shelter_staff_member, shelter: shelter)
      patch change_role_shelter_staff_path(shelter_id: shelter, id: staff), params: { shelter_role: "administrator" }
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(staff.reload.shelter_role).to eq("administrator")
    end

    it "rejects role changes from a non-owner" do
      administrator = create(:user, :verified, :shelter_administrator, :onboarding_completed, shelter: shelter)
      staff = create(:user, :verified, :onboarding_completed, :shelter_staff_member, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: administrator.email, password: "password123" } }

      patch change_role_shelter_staff_path(shelter_id: shelter, id: staff), params: { shelter_role: "administrator" }
      expect(response).to redirect_to(root_path)
      expect(staff.reload.shelter_role).to eq("staff_member")
    end

    it "prevents changing the owner's role" do
      patch change_role_shelter_staff_path(shelter_id: shelter, id: owner), params: { shelter_role: "staff_member" }
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(owner.reload.shelter_role).to eq("owner")
    end
  end

  describe "DELETE /shelters/:shelter_id/staff/:id" do
    it "removes a staff member" do
      staff = create(:user, :verified, :onboarding_completed, :shelter_staff_member, shelter: shelter)
      delete shelter_staff_path(shelter_id: shelter, id: staff)
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(staff.reload.shelter_id).to be_nil
      expect(staff.reload.shelter_role).to be_nil
    end

    it "prevents removing the owner" do
      delete shelter_staff_path(shelter_id: shelter, id: owner)
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(owner.reload.shelter_id).to eq(shelter.id)
    end

    it "rejects non-owner removal" do
      administrator = create(:user, :verified, :shelter_administrator, :onboarding_completed, shelter: shelter)
      staff = create(:user, :verified, :shelter_staff_member, :onboarding_completed, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: administrator.email, password: "password123" } }

      delete shelter_staff_path(shelter_id: shelter, id: staff)
      expect(response).to redirect_to(root_path)
      expect(staff.reload.shelter_id).to eq(shelter.id)
    end
  end

  describe "cross-shelter protection" do
    let(:shelter_b) { create(:shelter) }
    let(:owner_b) { create(:user, :verified, :shelter_owner, :onboarding_completed, shelter: shelter_b) }
    let(:staff_b) { create(:user, :verified, :shelter_staff_member, :onboarding_completed, shelter: shelter_b) }

    it "blocks the owner from viewing another shelter's staff list" do
      get shelter_staff_index_path(shelter_id: shelter_b)
      expect(response).to redirect_to(root_path)
    end

    it "blocks the owner from inviting staff to another shelter" do
      expect do
        post shelter_staff_index_path(shelter_id: shelter_b), params: { email: "x@example.com", role: "staff_member" }
      end.not_to change(Invitation, :count)
      expect(response).to redirect_to(root_path)
    end

    it "blocks the owner from changing another shelter member's role" do
      patch change_role_shelter_staff_path(shelter_id: shelter_b, id: staff_b), params: { shelter_role: "administrator" }
      expect(response).to redirect_to(root_path)
      expect(staff_b.reload.shelter_role).to eq("staff_member")
    end

    it "blocks the owner from removing another shelter member" do
      delete shelter_staff_path(shelter_id: shelter_b, id: staff_b)
      expect(response).to redirect_to(root_path)
      expect(staff_b.reload.shelter_id).to eq(shelter_b.id)
    end

    it "blocks the owner from editing another shelter's policies" do
      get edit_shelter_policies_path(shelter_id: shelter_b)
      expect(response).to redirect_to(root_path)
    end

    it "blocks the owner from viewing another shelter's dashboard" do
      get shelter_dashboard_path(shelter_id: shelter_b)
      expect(response).to redirect_to(root_path)
    end

    it "blocks the owner from editing another shelter's profile" do
      get edit_shelter_path(id: shelter_b)
      expect(response).to redirect_to(root_path)
    end
  end
end

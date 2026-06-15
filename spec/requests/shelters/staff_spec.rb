require "rails_helper"

RSpec.describe "Shelter Staff" do
  let(:shelter) { create(:shelter) }
  let(:admin) { create(:user, :verified, :admin, shelter: shelter) }

  before do
    post session_path, params: { session: { email: admin.email, password: "password123" } }
  end

  describe "GET /shelters/:shelter_id/staff" do
    it "lists staff members" do
      staff = create(:user, :verified, shelter: shelter)
      get shelter_staff_index_path(shelter_id: shelter)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(staff.name)
    end

    it "rejects non-admin access" do
      staff = create(:user, :verified, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      get shelter_staff_index_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /shelters/:shelter_id/staff" do
    it "invites a new staff member by email" do
      expect do
        post shelter_staff_index_path(shelter_id: shelter), params: { email: "newstaff@example.com" }
      end.to change(Invitation, :count).by(1)

      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
    end

    it "auto-adds existing users without a shelter" do
      existing = create(:user, :verified, email: "existing@example.com")
      expect do
        post shelter_staff_index_path(shelter_id: shelter), params: { email: "existing@example.com" }
      end.not_to change(Invitation, :count)

      expect(existing.reload.shelter).to eq(shelter)
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
    end

    it "rejects if email is already a member" do
      existing = create(:user, :verified, shelter: shelter)
      post shelter_staff_index_path(shelter_id: shelter), params: { email: existing.email }
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
    end
  end

  describe "DELETE /shelters/:shelter_id/staff/:id" do
    it "removes a staff member" do
      staff = create(:user, :verified, shelter: shelter)
      delete shelter_staff_path(shelter_id: shelter, id: staff)
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(staff.reload.shelter_id).to be_nil
    end

    it "prevents removing the last admin" do
      delete shelter_staff_path(shelter_id: shelter, id: admin)
      expect(response).to redirect_to(shelter_staff_index_path(shelter_id: shelter))
      expect(admin.reload.shelter_id).to eq(shelter.id)
    end

    it "rejects non-admin removal" do
      staff1 = create(:user, :verified, shelter: shelter)
      staff2 = create(:user, :verified, shelter: shelter)
      delete session_path
      post session_path, params: { session: { email: staff1.email, password: "password123" } }

      delete shelter_staff_path(shelter_id: shelter, id: staff2)
      expect(response).to redirect_to(root_path)
    end
  end
end

require "rails_helper"
require_relative "../../db/migrate/20260902000001_add_shelter_roles_and_invitation_roles"

# Verifies the AddShelterRolesAndInvitationRoles backfill (plan 46, DP-3):
#   shelter_admin -> owner, shelter_staff -> staff_member,
#   pending invitations -> staff_member, platform roles untouched,
#   and no shelter loses its owner.
#
# Runs the migration's up/down in isolation (DatabaseCleaner's transaction
# rolls the DDL back afterwards, so the shared test schema is unaffected).
RSpec.describe AddShelterRolesAndInvitationRoles do
  let(:shelter) { create(:shelter) }
  let!(:legacy_admin) { create(:user, :verified, role: "shelter_admin", shelter: shelter) }
  let!(:legacy_staff) { create(:user, :verified, role: "shelter_staff", shelter: shelter) }
  let!(:platform_admin) { create(:user, :verified, role: "admin") }
  let!(:legacy_invitation) { create(:invitation, shelter: shelter, created_by: legacy_admin, email: "legacy@example.com") }

  around do |example|
    # down drops the new columns (wiping any post-migration values), so up
    # re-runs the backfill against rows that only carry the legacy `role`
    # column. This exercises the migration's mapping logic exactly once.
    described_class.new.down
    described_class.new.up
    example.run
  end

  it "maps shelter_admin users to owner" do
    expect(legacy_admin.reload.shelter_role).to eq("owner")
  end

  it "maps shelter_staff users to staff_member" do
    expect(legacy_staff.reload.shelter_role).to eq("staff_member")
  end

  it "leaves platform roles untouched" do
    expect(platform_admin.reload.shelter_role).to be_nil
  end

  it "backfills pending invitations to staff_member" do
    expect(legacy_invitation.reload.role).to eq("staff_member")
  end

  it "keeps every shelter with an owner" do
    expect(shelter.users.shelter_owners).to include(legacy_admin)
    expect(shelter.users.shelter_owners.count).to eq(1)
  end
end

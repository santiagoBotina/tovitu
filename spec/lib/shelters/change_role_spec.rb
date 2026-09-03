require "rails_helper"

RSpec.describe Shelters::ChangeRole do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:owner) { create(:user, :verified, :shelter_owner, shelter: shelter) }

    context "by shelter owner" do
      it "changes a staff member's role" do
        staff = create(:user, :verified, :shelter_staff_member, shelter: shelter)
        result = described_class.call(shelter: shelter, actor: owner, member: staff, new_role: "administrator")
        expect(result).to be_success
        expect(staff.reload.shelter_role).to eq("administrator")
      end

      it "changes an administrator back to a staff member" do
        administrator = create(:user, :verified, :shelter_administrator, shelter: shelter)
        result = described_class.call(shelter: shelter, actor: owner, member: administrator, new_role: "staff_member")
        expect(result).to be_success
        expect(administrator.reload.shelter_role).to eq("staff_member")
      end

      it "returns failure when the target is the owner" do
        result = described_class.call(shelter: shelter, actor: owner, member: owner, new_role: "staff_member")
        expect(result).to be_failure
        expect(owner.reload.shelter_role).to eq("owner")
      end

      it "returns failure when assigning the owner role" do
        staff = create(:user, :verified, :shelter_staff_member, shelter: shelter)
        result = described_class.call(shelter: shelter, actor: owner, member: staff, new_role: "owner")
        expect(result).to be_failure
        expect(staff.reload.shelter_role).to eq("staff_member")
      end

      it "returns failure for an invalid role" do
        staff = create(:user, :verified, :shelter_staff_member, shelter: shelter)
        result = described_class.call(shelter: shelter, actor: owner, member: staff, new_role: "bogus")
        expect(result).to be_failure
      end
    end

    context "by non-owner" do
      it "returns failure" do
        administrator = create(:user, :verified, :shelter_administrator, shelter: shelter)
        staff = create(:user, :verified, :shelter_staff_member, shelter: shelter)
        result = described_class.call(shelter: shelter, actor: administrator, member: staff, new_role: "staff_member")
        expect(result).to be_failure
      end
    end

    context "with a member of another shelter" do
      it "returns failure (cross-shelter protection)" do
        other_shelter = create(:shelter)
        other_member = create(:user, :verified, :shelter_staff_member, shelter: other_shelter)
        result = described_class.call(shelter: shelter, actor: owner, member: other_member, new_role: "staff_member")
        expect(result).to be_failure
        expect(other_member.reload.shelter_role).to eq("staff_member")
      end
    end
  end
end

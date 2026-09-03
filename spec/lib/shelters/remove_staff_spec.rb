require "rails_helper"

RSpec.describe Shelters::RemoveStaff do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:owner) { create(:user, :verified, :shelter_owner, shelter: shelter) }
    let(:other_shelter) { create(:shelter) }
    let(:other_owner) { create(:user, :verified, :shelter_owner, shelter: other_shelter) }

    context "by shelter owner" do
      let(:staff) { create(:user, :verified, :shelter_staff_member, shelter: shelter) }

      it "removes a staff member and clears their membership" do
        result = described_class.call(shelter: shelter, user: owner, staff_user: staff)
        expect(result).to be_success
        expect(staff.reload.shelter_id).to be_nil
        expect(staff.reload.shelter_role).to be_nil
      end

      it "resets a shelter-account-type user to individual on removal" do
        described_class.call(shelter: shelter, user: owner, staff_user: staff)
        expect(staff.reload.role).to eq("individual")
        expect(staff.reload.shelter_user?).to be false
      end
    end

    context "when removing self" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, user: owner, staff_user: owner)
        expect(result).to be_failure
      end
    end

    context "when the target is the owner" do
      it "returns failure (owner cannot be removed by anyone)" do
        administrator = create(:user, :verified, :shelter_administrator, shelter: shelter)
        result = described_class.call(shelter: shelter, user: owner, staff_user: owner)
        expect(result).to be_failure
        expect(owner.reload.shelter_id).to eq(shelter.id)
        expect(administrator.reload.shelter_id).to eq(shelter.id)
      end
    end

    context "by non-owner" do
      let(:administrator) { create(:user, :verified, :shelter_administrator, shelter: shelter) }
      let(:staff) { create(:user, :verified, :shelter_staff_member, shelter: shelter) }

      it "returns failure" do
        result = described_class.call(shelter: shelter, user: administrator, staff_user: staff)
        expect(result).to be_failure
        expect(staff.reload.shelter_id).to eq(shelter.id)
      end
    end

    context "with user not from the same shelter" do
      let(:staff) { create(:user, :verified, :shelter_staff_member, shelter: shelter) }

      it "returns failure" do
        result = described_class.call(shelter: shelter, user: other_owner, staff_user: staff)
        expect(result).to be_failure
      end
    end

    context "with a target that is not a member of the shelter" do
      it "returns failure" do
        outsider = create(:user, :verified, :shelter_staff_member, shelter: other_shelter)
        result = described_class.call(shelter: shelter, user: owner, staff_user: outsider)
        expect(result).to be_failure
      end
    end
  end
end

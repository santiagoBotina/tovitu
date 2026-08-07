require "rails_helper"

RSpec.describe Shelters::RemoveStaff do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:admin) { create(:user, :verified, shelter: shelter, role: "shelter_admin") }
    let(:other_shelter) { create(:shelter) }
    let(:other_admin) { create(:user, :verified, shelter: other_shelter, role: "shelter_admin") }

    context "by shelter admin" do
      let(:staff) { create(:user, :verified, shelter: shelter, role: "staff") }

      it "removes staff member" do
        result = described_class.call(shelter: shelter, user: admin, staff_user: staff)
        expect(result).to be_success
        expect(staff.reload.shelter_id).to be_nil
        expect(staff.reload.role).to eq("shelter_staff")
      end
    end

    context "when removing self" do
      it "returns failure when self" do
        result = described_class.call(shelter: shelter, user: admin, staff_user: admin)
        expect(result).to be_failure
      end
    end

    context "by non-admin" do
      let(:staff) { create(:user, :verified, shelter: shelter, role: "staff") }
      let(:other_staff) { create(:user, :verified, shelter: shelter, role: "staff") }

      it "returns failure" do
        result = described_class.call(shelter: shelter, user: staff, staff_user: other_staff)
        expect(result).to be_failure
      end
    end

    context "with user not from the same shelter" do
      let(:staff) { create(:user, :verified, shelter: shelter, role: "staff") }

      it "returns failure" do
        result = described_class.call(shelter: shelter, user: other_admin, staff_user: staff)
        expect(result).to be_failure
      end
    end
  end
end

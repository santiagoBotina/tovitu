require "rails_helper"

RSpec.describe Shelters::InviteStaff do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:admin) { create(:user, :verified, shelter: shelter, role: "shelter_admin") }

    context "by shelter admin" do
      it "creates an invitation for new email" do
        result = described_class.call(shelter: shelter, inviter: admin, email: "newstaff@example.com")
        expect(result).to be_success
        expect(result.data).to be_an(Invitation)
      end

      it "adds existing user without shelter to staff" do
        existing_user = create(:user, :verified)
        result = described_class.call(shelter: shelter, inviter: admin, email: existing_user.email)
        expect(result).to be_success
        expect(existing_user.reload.shelter_id).to eq(shelter.id)
        expect(existing_user.reload.role).to eq("staff")
      end

      it "returns failure if user already belongs to this shelter" do
        staff = create(:user, :verified, shelter: shelter, role: "staff")
        result = described_class.call(shelter: shelter, inviter: admin, email: staff.email)
        expect(result).to be_failure
      end

      it "returns failure if user belongs to another shelter" do
        other_shelter = create(:shelter)
        other_user = create(:user, :verified, shelter: other_shelter)
        result = described_class.call(shelter: shelter, inviter: admin, email: other_user.email)
        expect(result).to be_failure
      end
    end

    context "with invalid email" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, inviter: admin, email: "invalid")
        expect(result).to be_failure
      end
    end

    context "by non-admin" do
      let(:staff) { create(:user, :verified, shelter: shelter, role: "staff") }

      it "returns failure" do
        result = described_class.call(shelter: shelter, inviter: staff, email: "test@example.com")
        expect(result).to be_failure
      end
    end

    context "by admin from different shelter" do
      let(:other_admin) { create(:user, :verified, :shelter_admin) }

      it "returns failure" do
        result = described_class.call(shelter: shelter, inviter: other_admin, email: "test@example.com")
        expect(result).to be_failure
      end
    end
  end
end

require "rails_helper"

RSpec.describe Shelters::InviteStaff do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:owner) { create(:user, :verified, :shelter_owner, shelter: shelter) }

    context "by shelter owner" do
      it "creates an invitation with the role for a new email" do
        result = described_class.call(shelter: shelter, inviter: owner, email: "newstaff@example.com", role: "staff_member")
        expect(result).to be_success
        expect(result.data).to be_an(Invitation)
        expect(result.data.role).to eq("staff_member")
      end

      it "stores an administrator role on the invitation" do
        result = described_class.call(shelter: shelter, inviter: owner, email: "newadmin@example.com", role: "administrator")
        expect(result).to be_success
        expect(result.data.role).to eq("administrator")
      end

      it "no longer auto-promotes an existing registered user (always invites with a role)" do
        existing_user = create(:user, :verified)
        result = described_class.call(shelter: shelter, inviter: owner, email: existing_user.email, role: "staff_member")
        expect(result).to be_success
        expect(result.data).to be_an(Invitation)
        expect(existing_user.reload.shelter_id).to be_nil
      end

      it "returns failure if user already belongs to this shelter" do
        staff = create(:user, :verified, :shelter_staff_member, shelter: shelter)
        result = described_class.call(shelter: shelter, inviter: owner, email: staff.email, role: "staff_member")
        expect(result).to be_failure
      end

      it "returns failure if user belongs to another shelter" do
        other_shelter = create(:shelter)
        other_user = create(:user, :verified, :shelter_staff_member, shelter: other_shelter)
        result = described_class.call(shelter: shelter, inviter: owner, email: other_user.email, role: "staff_member")
        expect(result).to be_failure
      end

      it "returns failure when no role is provided" do
        result = described_class.call(shelter: shelter, inviter: owner, email: "newstaff@example.com", role: "")
        expect(result).to be_failure
      end

      it "returns failure when trying to invite an owner" do
        result = described_class.call(shelter: shelter, inviter: owner, email: "newowner@example.com", role: "owner")
        expect(result).to be_failure
      end

      it "returns failure when the email already has a pending invitation" do
        first = described_class.call(shelter: shelter, inviter: owner, email: "dup@example.com", role: "staff_member")
        expect(first).to be_success

        duplicate = described_class.call(shelter: shelter, inviter: owner, email: "dup@example.com", role: "administrator")
        expect(duplicate).to be_failure
        expect(shelter.invitations.pending.where(email: "dup@example.com").count).to eq(1)
      end
    end

    context "with invalid email" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, inviter: owner, email: "invalid", role: "staff_member")
        expect(result).to be_failure
      end
    end

    context "by non-owner" do
      let(:administrator) { create(:user, :verified, :shelter_administrator, shelter: shelter) }

      it "returns failure" do
        result = described_class.call(shelter: shelter, inviter: administrator, email: "test@example.com", role: "staff_member")
        expect(result).to be_failure
      end
    end

    context "by owner from different shelter" do
      let(:other_shelter) { create(:shelter) }
      let(:other_owner) { create(:user, :verified, :shelter_owner, shelter: other_shelter) }

      it "returns failure" do
        result = described_class.call(shelter: shelter, inviter: other_owner, email: "test@example.com", role: "staff_member")
        expect(result).to be_failure
      end
    end
  end
end

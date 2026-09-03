require "rails_helper"

RSpec.describe Shelters::AcceptInvitation do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:user) { create(:user, :verified) }

    context "with valid invitation" do
      it "activates membership with the stored role" do
        invitation = create(:invitation, role: "staff_member", shelter: shelter, email: user.email)
        described_class.call(token: invitation.token, user: user)
        expect(user.reload.shelter_id).to eq(shelter.id)
        expect(user.reload.shelter_role).to eq("staff_member")
      end

      it "activates membership with an administrator role" do
        invitation = create(:invitation, role: "administrator", shelter: shelter, email: user.email)
        described_class.call(token: invitation.token, user: user)
        expect(user.reload.shelter_role).to eq("administrator")
      end

      it "accepts the invitation" do
        invitation = create(:invitation, shelter: shelter, email: user.email)
        described_class.call(token: invitation.token, user: user)
        expect(invitation.reload).to be_accepted
      end

      it "returns success" do
        invitation = create(:invitation, shelter: shelter, email: user.email)
        result = described_class.call(token: invitation.token, user: user)
        expect(result).to be_success
        expect(result.data).to eq(shelter)
      end
    end

    context "with invalid token" do
      it "returns failure" do
        result = described_class.call(token: "invalid", user: user)
        expect(result).to be_failure
      end
    end

    context "with expired invitation" do
      it "returns failure" do
        expired_invitation = create(:invitation, :expired, shelter: shelter)
        result = described_class.call(token: expired_invitation.token, user: user)
        expect(result).to be_failure
      end
    end

    context "with already accepted invitation" do
      it "returns failure" do
        accepted_invitation = create(:invitation, :accepted, shelter: shelter)
        result = described_class.call(token: accepted_invitation.token, user: user)
        expect(result).to be_failure
      end
    end

    context "with a cancelled invitation" do
      it "returns failure" do
        cancelled_invitation = create(:invitation, :cancelled, shelter: shelter)
        result = described_class.call(token: cancelled_invitation.token, user: user)
        expect(result).to be_failure
        expect(user.reload.shelter_id).to be_nil
      end
    end

    context "when the user already belongs to a shelter" do
      it "returns failure and does not reassign the user" do
        other_shelter = create(:shelter)
        member = create(:user, :verified, :shelter_staff_member, shelter: other_shelter)
        invitation = create(:invitation, shelter: shelter)

        result = described_class.call(token: invitation.token, user: member)
        expect(result).to be_failure
        expect(member.reload.shelter_id).to eq(other_shelter.id)
        expect(invitation.reload).not_to be_accepted
      end
    end

    context "when the invitation was sent to a different email" do
      it "returns failure and does not activate the membership" do
        invitation = create(:invitation, shelter: shelter, email: "intended@example.com", role: "staff_member")
        attacker = create(:user, :verified, email: "attacker@example.com")

        result = described_class.call(token: invitation.token, user: attacker)
        expect(result).to be_failure
        expect(attacker.reload.shelter_id).to be_nil
        expect(invitation.reload).not_to be_accepted
      end
    end

    context "when the invitation carries the owner role (defense-in-depth)" do
      it "returns failure and does not create a second owner" do
        invitation = create(:invitation, shelter: shelter)
        allow(Invitation).to receive(:find_by).and_return(invitation)
        allow(invitation).to receive(:role).and_return("owner")

        result = described_class.call(token: invitation.token, user: user)
        expect(result).to be_failure
        expect(user.reload.shelter_id).to be_nil
        expect(invitation.reload).not_to be_accepted
      end
    end
  end
end

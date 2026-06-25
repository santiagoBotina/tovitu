require "rails_helper"

RSpec.describe Shelters::AcceptInvitation do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:invitation) { create(:invitation, shelter: shelter) }
    let(:user) { create(:user, :verified) }

    context "with valid invitation" do
      it "updates the user" do
        described_class.call(token: invitation.token, user: user)
        expect(user.reload.shelter_id).to eq(shelter.id)
        expect(user.reload.role).to eq("staff")
      end

      it "accepts the invitation" do
        described_class.call(token: invitation.token, user: user)
        expect(invitation.reload).to be_accepted
      end

      it "returns success" do
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
      let(:expired_invitation) { create(:invitation, :expired, shelter: shelter) }

      it "returns failure" do
        result = described_class.call(token: expired_invitation.token, user: user)
        expect(result).to be_failure
      end
    end

    context "with already accepted invitation" do
      let(:accepted_invitation) { create(:invitation, :accepted, shelter: shelter) }

      it "returns failure" do
        result = described_class.call(token: accepted_invitation.token, user: user)
        expect(result).to be_failure
      end
    end
  end
end

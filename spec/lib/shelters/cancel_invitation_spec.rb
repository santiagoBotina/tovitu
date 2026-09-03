require "rails_helper"

RSpec.describe Shelters::CancelInvitation do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:owner) { create(:user, :verified, :shelter_owner, shelter: shelter) }

    context "by shelter owner" do
      it "cancels a pending invitation" do
        invitation = create(:invitation, shelter: shelter, created_by: owner)
        result = described_class.call(shelter: shelter, actor: owner, invitation: invitation)
        expect(result).to be_success
        expect(invitation.reload).to be_cancelled
      end
    end

    context "by non-owner" do
      it "returns failure" do
        administrator = create(:user, :verified, :shelter_administrator, shelter: shelter)
        invitation = create(:invitation, shelter: shelter, created_by: owner)
        result = described_class.call(shelter: shelter, actor: administrator, invitation: invitation)
        expect(result).to be_failure
        expect(invitation.reload).not_to be_cancelled
      end
    end

    context "with an invitation from another shelter" do
      it "returns failure (cross-shelter protection)" do
        other_shelter = create(:shelter)
        invitation = create(:invitation, shelter: other_shelter)
        result = described_class.call(shelter: shelter, actor: owner, invitation: invitation)
        expect(result).to be_failure
        expect(invitation.reload).not_to be_cancelled
      end
    end

    context "with an already accepted invitation" do
      it "returns failure" do
        invitation = create(:invitation, :accepted, shelter: shelter, created_by: owner)
        result = described_class.call(shelter: shelter, actor: owner, invitation: invitation)
        expect(result).to be_failure
      end
    end

    context "with an already cancelled invitation" do
      it "returns failure" do
        invitation = create(:invitation, :cancelled, shelter: shelter, created_by: owner)
        result = described_class.call(shelter: shelter, actor: owner, invitation: invitation)
        expect(result).to be_failure
      end
    end
  end
end

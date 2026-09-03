require "rails_helper"

RSpec.describe ShelterPolicy do
  subject(:policy) { described_class.new(user, shelter) }

  let(:shelter) { create(:shelter) }

  context "when the user is the shelter owner" do
    let(:user) { create(:user, :shelter_owner, shelter: shelter) }

    it { expect(policy.manage?).to be true }
    it { expect(policy.edit?).to be true }
    it { expect(policy.update?).to be true }
    it { expect(policy.staff_index?).to be true }
    it { expect(policy.staff_create?).to be true }
    it { expect(policy.staff_destroy?).to be true }
    it { expect(policy.staff_change_role?).to be true }
    it { expect(policy.invitations_cancel?).to be true }
    it { expect(policy.policies_edit?).to be true }
    it { expect(policy.policies_update?).to be true }
    it { expect(policy.dashboard?).to be true }
  end

  context "when the user is an administrator of the same shelter" do
    let(:user) { create(:user, :shelter_administrator, shelter: shelter) }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.update?).to be false }
    it { expect(policy.staff_index?).to be true }
    it { expect(policy.staff_create?).to be false }
    it { expect(policy.staff_destroy?).to be false }
    it { expect(policy.staff_change_role?).to be false }
    it { expect(policy.invitations_cancel?).to be false }
    it { expect(policy.policies_edit?).to be true }
    it { expect(policy.policies_update?).to be true }
    it { expect(policy.dashboard?).to be true }
  end

  context "when the user is a staff member of the same shelter" do
    let(:user) { create(:user, :shelter_staff_member, shelter: shelter) }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.update?).to be false }
    it { expect(policy.staff_index?).to be false }
    it { expect(policy.staff_create?).to be false }
    it { expect(policy.staff_destroy?).to be false }
    it { expect(policy.staff_change_role?).to be false }
    it { expect(policy.invitations_cancel?).to be false }
    it { expect(policy.policies_edit?).to be false }
    it { expect(policy.policies_update?).to be false }
    it { expect(policy.dashboard?).to be true }
  end

  context "when the user belongs to a different shelter" do
    let(:user) { create(:user, :shelter_owner, shelter: create(:shelter)) }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.dashboard?).to be false }
    it { expect(policy.staff_index?).to be false }
    it { expect(policy.staff_create?).to be false }
    it { expect(policy.policies_edit?).to be false }
  end

  context "when the user is an individual" do
    let(:user) { create(:user) }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.staff_index?).to be false }
    it { expect(policy.policies_edit?).to be false }
    it { expect(policy.dashboard?).to be false }
  end

  context "when the user has a shelter_id but no shelter role (data drift)" do
    let(:user) { create(:user, shelter_id: shelter.id) }

    it "cannot access the dashboard without an active membership" do
      expect(policy.dashboard?).to be false
    end

    it { expect(policy.manage?).to be false }
    it { expect(policy.staff_index?).to be false }
    it { expect(policy.policies_edit?).to be false }
  end

  context "when there is no user" do
    let(:user) { nil }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.dashboard?).to be false }
  end
end

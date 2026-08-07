require "rails_helper"

RSpec.describe ShelterPolicy do
  subject(:policy) { described_class.new(user, shelter) }

  let(:shelter) { create(:shelter) }

  context "when the user is the shelter admin" do
    let(:user) { create(:user, :shelter_admin, shelter: shelter) }

    it { expect(policy.manage?).to be true }
    it { expect(policy.edit?).to be true }
    it { expect(policy.update?).to be true }
    it { expect(policy.staff_index?).to be true }
    it { expect(policy.staff_create?).to be true }
    it { expect(policy.staff_destroy?).to be true }
    it { expect(policy.policies_edit?).to be true }
    it { expect(policy.policies_update?).to be true }
    it { expect(policy.dashboard?).to be true }
  end

  context "when the user is shelter staff of the same shelter" do
    let(:user) { create(:user, :shelter_staff, shelter: shelter) }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.update?).to be false }
    it { expect(policy.staff_index?).to be false }
    it { expect(policy.staff_create?).to be false }
    it { expect(policy.staff_destroy?).to be false }
    it { expect(policy.policies_edit?).to be false }
    it { expect(policy.policies_update?).to be false }

    it "may still view the dashboard" do
      expect(policy.dashboard?).to be true
    end
  end

  context "when the user belongs to a different shelter" do
    let(:user) { create(:user, :shelter_admin, shelter: create(:shelter)) }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.dashboard?).to be false }
  end

  context "when the user is an individual" do
    let(:user) { create(:user) }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.staff_index?).to be false }
    it { expect(policy.policies_edit?).to be false }
    it { expect(policy.dashboard?).to be false }
  end

  context "when there is no user" do
    let(:user) { nil }

    it { expect(policy.manage?).to be false }
    it { expect(policy.edit?).to be false }
    it { expect(policy.dashboard?).to be false }
  end
end

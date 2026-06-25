require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shelter) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "validations" do
    subject { build(:invitation) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:token) }

    it "validates email format" do
      inv = build(:invitation, email: "invalid")
      inv.valid?
      expect(inv.errors[:email]).to be_present
    end
  end

  describe "callbacks" do
    it "generates token on create" do
      inv = create(:invitation, token: nil)
      expect(inv.token).to be_present
      expect(inv.token.length).to be >= 32
    end

    it "sets expiry to 7 days from now on create" do
      inv = create(:invitation, expires_at: nil)
      expect(inv.expires_at).to be_within(1.second).of(7.days.from_now)
    end
  end

  describe "scopes" do
    let(:shelter) { create(:shelter) }
    let!(:pending_inv) { create(:invitation, shelter: shelter, expires_at: 7.days.from_now) }
    let!(:expired_inv) { create(:invitation, :expired, shelter: shelter) }
    let!(:accepted_inv) { create(:invitation, :accepted, shelter: shelter) }

    it "pending" do
      expect(Invitation.pending).to include(pending_inv)
      expect(Invitation.pending).not_to include(expired_inv, accepted_inv)
    end

    it "expired" do
      expect(Invitation.expired).to include(expired_inv)
    end

    it "accepted" do
      expect(Invitation.accepted).to include(accepted_inv)
    end
  end

  describe "#expired?" do
    it "returns true when past expiry" do
      inv = build(:invitation, :expired)
      expect(inv).to be_expired
    end

    it "returns false when not expired" do
      inv = build(:invitation)
      expect(inv).not_to be_expired
    end
  end

  describe "#accepted?" do
    it "returns true when accepted_at is set" do
      inv = build(:invitation, :accepted)
      expect(inv).to be_accepted
    end

    it "returns false when accepted_at is nil" do
      inv = build(:invitation)
      expect(inv).not_to be_accepted
    end
  end

  describe "#accept!" do
    it "sets accepted_at" do
      inv = create(:invitation)
      expect { inv.accept! }.to change(inv, :accepted_at).from(nil)
    end
  end
end

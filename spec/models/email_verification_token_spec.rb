require "rails_helper"

RSpec.describe EmailVerificationToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe "secure token" do
    it "generates a token on create" do
      token = create(:email_verification_token)
      expect(token.token).to be_present
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      token = build(:email_verification_token, expires_at: 1.minute.ago)
      expect(token).to be_expired
    end

    it "returns false when expires_at is in the future" do
      token = build(:email_verification_token, expires_at: 1.hour.from_now)
      expect(token).not_to be_expired
    end
  end

  describe "#consumed?" do
    it "returns true when consumed_at is set" do
      token = build(:email_verification_token, consumed_at: Time.current)
      expect(token).to be_consumed
    end

    it "returns false when consumed_at is nil" do
      token = build(:email_verification_token)
      expect(token).not_to be_consumed
    end
  end

  describe "#consume!" do
    it "sets consumed_at to current time" do
      token = create(:email_verification_token)
      expect { token.consume! }.to change(token, :consumed_at).from(nil)
    end
  end
end

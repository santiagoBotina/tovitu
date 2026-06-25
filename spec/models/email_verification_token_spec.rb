require "rails_helper"

RSpec.describe EmailVerificationToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:valid_token) { create(:email_verification_token, user: user, expires_at: 1.hour.from_now) }
    let!(:expired_token) { create(:email_verification_token, user: user, expires_at: 1.hour.ago) }
    let!(:consumed_token) { create(:email_verification_token, user: user, consumed_at: Time.current) }

    it "unexpired" do
      expect(EmailVerificationToken.unexpired).to include(valid_token)
      expect(EmailVerificationToken.unexpired).not_to include(expired_token)
    end

    it "unconsumed" do
      expect(EmailVerificationToken.unconsumed).to include(valid_token, expired_token)
      expect(EmailVerificationToken.unconsumed).not_to include(consumed_token)
    end
  end

  describe "#expired?" do
    it "returns true when past expiry" do
      token = build(:email_verification_token, expires_at: 1.hour.ago)
      expect(token).to be_expired
    end

    it "returns false when not expired" do
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
    it "sets consumed_at" do
      token = create(:email_verification_token)
      expect { token.consume! }.to change(token, :consumed_at).from(nil)
    end
  end

  describe ".valid_token" do
    let(:user) { create(:user) }
    let!(:token) { create(:email_verification_token, user: user) }

    it "finds unconsumed token" do
      expect(EmailVerificationToken.valid_token(token.token)).to eq(token)
    end

    it "returns nil for nil" do
      expect(EmailVerificationToken.valid_token(nil)).to be_nil
    end

    it "returns nil for consumed token" do
      token.consume!
      expect(EmailVerificationToken.valid_token(token.token)).to be_nil
    end
  end
end

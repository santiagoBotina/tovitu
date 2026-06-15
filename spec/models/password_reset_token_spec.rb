require "rails_helper"

RSpec.describe PasswordResetToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe "secure token" do
    it "generates a token on create" do
      token = create(:password_reset_token)
      expect(token.token).to be_present
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      token = build(:password_reset_token, expires_at: 1.minute.ago)
      expect(token).to be_expired
    end

    it "returns false when expires_at is in the future" do
      token = build(:password_reset_token, expires_at: 1.hour.from_now)
      expect(token).not_to be_expired
    end
  end

  describe "#consume!" do
    it "sets consumed_at to current time" do
      token = create(:password_reset_token)
      expect { token.consume! }.to change(token, :consumed_at).from(nil)
    end
  end
end

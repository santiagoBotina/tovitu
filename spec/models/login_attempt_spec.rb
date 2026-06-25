require "rails_helper"

RSpec.describe LoginAttempt, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:ip_address) }
  end

  describe "scopes" do
    let(:email) { "test@example.com" }

    before do
      create(:login_attempt, email: email, attempted_at: 1.hour.ago, success: true)
      create(:login_attempt, email: email, attempted_at: 5.minutes.ago, success: false)
      create(:login_attempt, email: email, attempted_at: 2.minutes.ago, success: false)
      create(:login_attempt, email: "other@example.com", attempted_at: 1.minute.ago, success: true)
    end

    it "recent returns attempts within 15 minutes" do
      expect(LoginAttempt.recent.count).to eq(3)
    end

    it "failed returns unsuccessful attempts" do
      expect(LoginAttempt.failed.count).to eq(2)
    end

    it "by_email filters by email" do
      expect(LoginAttempt.by_email(email).count).to eq(3)
    end
  end

  describe ".recent_failures_for" do
    it "returns recent failed attempts for an email" do
      email = "test@example.com"
      create(:login_attempt, email: email, attempted_at: 2.minutes.ago, success: false)
      create(:login_attempt, email: email, attempted_at: 1.minute.ago, success: true)

      result = LoginAttempt.recent_failures_for(email)
      expect(result.count).to eq(1)
    end
  end

  describe ".locked_out?" do
    let(:email) { "test@example.com" }

    it "returns false when under 5 failures" do
      expect(LoginAttempt.locked_out?(email)).to be false
    end

    it "returns true when 5 or more recent failures" do
      create_list(:login_attempt, 5, email: email, attempted_at: 1.minute.ago, success: false)
      expect(LoginAttempt.locked_out?(email)).to be true
    end
  end

  describe ".lockout_ends_at" do
    let(:email) { "test@example.com" }

    it "returns nil when not locked out" do
      expect(LoginAttempt.lockout_ends_at(email)).to be_nil
    end

    it "returns time 15 minutes after latest failure when locked out" do
      create_list(:login_attempt, 5, email: email, attempted_at: 1.minute.ago, success: false)
      expect(LoginAttempt.lockout_ends_at(email)).to be_within(1.second).of(14.minutes.from_now)
    end
  end

  describe ".lockout_remaining_seconds" do
    it "returns 0 when not locked out" do
      expect(LoginAttempt.lockout_remaining_seconds("test@example.com")).to eq(0)
    end
  end
end

require "rails_helper"

RSpec.describe LoginAttempt, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:ip_address) }
  end

  describe "scopes" do
    let(:email) { "test@example.com" }

    before do
      travel_to 20.minutes.ago do
        create(:login_attempt, email: email, success: false)
      end
      travel_to 10.minutes.ago do
        create(:login_attempt, email: email, success: false)
      end
      create(:login_attempt, email: email, success: true)
      create(:login_attempt, email: "other@example.com", success: false)
    end

    describe ".recent" do
      it "returns attempts within the last 15 minutes" do
        expect(LoginAttempt.recent.count).to eq(3)
      end
    end

    describe ".failed" do
      it "returns only failed attempts" do
        expect(LoginAttempt.failed.count).to eq(3)
      end
    end

    describe ".by_email" do
      it "returns attempts for a specific email" do
        expect(LoginAttempt.by_email(email).count).to eq(3)
      end
    end

    describe ".recent_failures_for" do
      it "returns recent failed attempts for the email" do
        expect(LoginAttempt.recent_failures_for(email).count).to eq(1)
      end
    end
  end

  describe ".locked_out?" do
    let(:email) { "test@example.com" }

    it "returns true when there are 5+ recent failures" do
      5.times { create(:login_attempt, email: email, success: false) }
      expect(LoginAttempt.locked_out?(email)).to be true
    end

    it "returns false when there are fewer than 5 recent failures" do
      2.times { create(:login_attempt, email: email, success: false) }
      expect(LoginAttempt.locked_out?(email)).to be false
    end

    it "returns false when previous failures are outside the 15 min window" do
      travel_to 16.minutes.ago do
        5.times { create(:login_attempt, email: email, success: false) }
      end
      expect(LoginAttempt.locked_out?(email)).to be false
    end
  end

  describe ".lockout_remaining_seconds" do
    it "returns 0 when not locked out" do
      expect(LoginAttempt.lockout_remaining_seconds("test@example.com")).to eq(0)
    end
  end
end

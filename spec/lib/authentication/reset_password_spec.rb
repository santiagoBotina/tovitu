require "rails_helper"

RSpec.describe Authentication::ResetPassword do
  let(:user) { create(:user) }
  let!(:token) { create(:password_reset_token, user: user) }

  describe "#call" do
    context "with valid token" do
      it "updates the password" do
        expect {
          described_class.call(token: token.token, password: "newpass123", password_confirmation: "newpass123")
        }.to change { user.reload.authenticate("newpass123") }.from(false).to be_truthy
      end

      it "consumes the token" do
        expect {
          described_class.call(token: token.token, password: "newpass123", password_confirmation: "newpass123")
        }.to change { token.reload.consumed? }.from(false).to(true)
      end

      it "returns success with user data" do
        result = described_class.call(token: token.token, password: "newpass123", password_confirmation: "newpass123")
        expect(result).to be_success
        expect(result.data[:email]).to eq(user.email)
      end
    end

    context "with invalid token" do
      it "returns failure" do
        result = described_class.call(token: "invalid", password: "newpass123", password_confirmation: "newpass123")
        expect(result).to be_failure
        expect(result.error_code).to eq(:invalid_token)
      end
    end

    context "with expired token" do
      let(:expired_token) { create(:password_reset_token, user: user, expires_at: 1.hour.ago) }

      it "returns failure" do
        result = described_class.call(token: expired_token.token, password: "newpass123", password_confirmation: "newpass123")
        expect(result).to be_failure
        expect(result.error_code).to eq(:expired)
      end
    end

    context "with consumed token" do
      before { token.consume! }

      it "returns failure" do
        result = described_class.call(token: token.token, password: "newpass123", password_confirmation: "newpass123")
        expect(result).to be_failure
      end
    end

    context "with invalid password" do
      it "returns failure when passwords don't match" do
        result = described_class.call(token: token.token, password: "newpass123", password_confirmation: "different")
        expect(result).to be_failure
      end

      it "returns failure when password too short" do
        result = described_class.call(token: token.token, password: "short", password_confirmation: "short")
        expect(result).to be_failure
      end
    end
  end
end

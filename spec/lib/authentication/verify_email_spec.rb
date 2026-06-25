require "rails_helper"

RSpec.describe Authentication::VerifyEmail do
  let(:user) { create(:user) }
  let!(:token) { create(:email_verification_token, user: user) }

  describe "#call" do
    context "with valid token" do
      it "returns a successful Result" do
        result = described_class.call(token: token.token)
        expect(result).to be_success
      end

      it "verifies the user" do
        expect { described_class.call(token: token.token) }
          .to change { user.reload.verified? }.from(false).to(true)
      end

      it "consumes the token" do
        expect { described_class.call(token: token.token) }
          .to change { token.reload.consumed? }.from(false).to(true)
      end

      it "returns user data" do
        result = described_class.call(token: token.token)
        expect(result.data[:verified]).to be true
        expect(result.data[:email]).to eq(user.email)
      end
    end

    context "with invalid token" do
      it "returns failure" do
        result = described_class.call(token: "invalid")
        expect(result).to be_failure
        expect(result.error_code).to eq(:invalid_token)
      end
    end

    context "with expired token" do
      let(:expired_token) { create(:email_verification_token, user: user, expires_at: 1.hour.ago) }

      it "returns failure" do
        result = described_class.call(token: expired_token.token)
        expect(result).to be_failure
        expect(result.error_code).to eq(:expired)
      end
    end

    context "with consumed token" do
      before { token.consume! }

      it "returns failure" do
        result = described_class.call(token: token.token)
        expect(result).to be_failure
      end
    end
  end
end

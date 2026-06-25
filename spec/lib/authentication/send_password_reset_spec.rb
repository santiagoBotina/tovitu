require "rails_helper"

RSpec.describe Authentication::SendPasswordReset do
  describe "#call" do
    context "with verified user" do
      let(:user) { create(:user, :verified) }

      it "creates a password reset token" do
        expect { described_class.call(email: user.email) }
          .to change(PasswordResetToken, :count).by(1)
      end

      it "sends password reset email" do
        expect { described_class.call(email: user.email) }
          .to have_enqueued_mail(AuthenticationMailer, :password_reset)
      end

      it "returns success" do
        result = described_class.call(email: user.email)
        expect(result).to be_success
      end
    end

    context "with non-existent email" do
      it "returns success (to not leak user existence)" do
        result = described_class.call(email: "nonexistent@example.com")
        expect(result).to be_success
      end

      it "does not send email" do
        expect { described_class.call(email: "nonexistent@example.com") }
          .not_to have_enqueued_mail(AuthenticationMailer, :password_reset)
      end
    end

    context "with unverified user" do
      let(:user) { create(:user) }

      it "returns success but does not send email" do
        result = described_class.call(email: user.email)
        expect(result).to be_success
      end

      it "does not send email" do
        expect { described_class.call(email: user.email) }
          .not_to have_enqueued_mail(AuthenticationMailer, :password_reset)
      end
    end

    context "with discarded user" do
      let(:user) { create(:user, :verified, :discarded) }

      it "returns success (to not leak user existence)" do
        result = described_class.call(email: user.email)
        expect(result).to be_success
      end
    end

    it "normalizes email before lookup" do
      user = create(:user, :verified, email: "Test@Example.com")
      result = described_class.call(email: "  TEST@EXAMPLE.COM  ")
      expect(result).to be_success
    end
  end
end

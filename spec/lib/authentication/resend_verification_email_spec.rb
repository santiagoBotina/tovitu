require "rails_helper"

RSpec.describe Authentication::ResendVerificationEmail do
  describe "#call" do
    context "with unverified user" do
      let(:user) { create(:user) }

      it "creates a new verification token" do
        expect { described_class.call(user: user) }
          .to change(EmailVerificationToken, :count).by(1)
      end

      it "sends verification email" do
        expect { described_class.call(user: user) }
          .to have_enqueued_mail(AuthenticationMailer, :verification)
      end

      it "returns success" do
        result = described_class.call(user: user)
        expect(result).to be_success
      end
    end

    context "with verified user" do
      let(:user) { create(:user, :verified) }

      it "returns failure" do
        result = described_class.call(user: user)
        expect(result).to be_failure
      end

      it "does not send email" do
        expect { described_class.call(user: user) }
          .not_to have_enqueued_mail(AuthenticationMailer, :verification)
      end
    end
  end
end

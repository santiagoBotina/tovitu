require "rails_helper"

RSpec.describe Authentication::AuthenticateUser do
  let(:password) { "password123" }
  let(:user) { create(:user, :verified, email: "test@example.com", password: password, password_confirmation: password) }

  describe "#call" do
    context "with valid credentials" do
      it "returns a successful Result" do
        result = described_class.call(email: user.email, password: password)
        expect(result).to be_success
      end

      it "returns user data" do
        result = described_class.call(email: user.email, password: password)
        expect(result.data[:id]).to eq(user.id)
        expect(result.data[:verified]).to be true
      end

      it "logs a successful attempt" do
        expect { described_class.call(email: user.email, password: password) }
          .to change(LoginAttempt, :count).by(1)
        expect(LoginAttempt.last).to be_success
      end
    end

    context "with unverified account" do
      let(:unverified_user) { create(:user, email: "unverified@example.com", password: password, password_confirmation: password) }

      it "returns failure" do
        result = described_class.call(email: unverified_user.email, password: password)
        expect(result).to be_failure
        expect(result.error_code).to eq(:unverified)
      end

      it "resends verification email" do
        expect { described_class.call(email: unverified_user.email, password: password) }
          .to have_enqueued_mail(AuthenticationMailer, :verification)
      end
    end

    context "with invalid credentials" do
      it "returns failure" do
        result = described_class.call(email: user.email, password: "wrong")
        expect(result).to be_failure
        expect(result.error_code).to eq(:invalid_credentials)
      end
    end

    context "with non-existent email" do
      it "returns failure" do
        result = described_class.call(email: "nonexistent@example.com", password: password)
        expect(result).to be_failure
      end
    end

    context "with role mismatch" do
      let(:shelter_user) { create(:user, :verified, :shelter_admin, password: password, password_confirmation: password) }

      it "returns failure when role doesn't match" do
        result = described_class.call(email: shelter_user.email, password: password, role: "adopter")
        expect(result).to be_failure
        expect(result.error_code).to eq(:role_mismatch)
      end

      it "allows adopter role for adopter users" do
        result = described_class.call(email: user.email, password: password, role: "adopter")
        expect(result).to be_success
      end

      it "allows shelter role for shelter users" do
        result = described_class.call(email: shelter_user.email, password: password, role: "shelter")
        expect(result).to be_success
      end
    end

    context "when locked out" do
      let(:email) { "locked@example.com" }

      before do
        create_list(:login_attempt, 5, email: email, attempted_at: 1.minute.ago, success: false)
      end

      it "returns failure" do
        result = described_class.call(email: email, password: password)
        expect(result).to be_failure
        expect(result.error_code).to eq(:locked)
      end
    end

    context "with onboarding_completed user" do
      let(:onboarded_user) { create(:user, :verified, :onboarding_completed, password: password, password_confirmation: password) }

      it "returns onboarding status" do
        result = described_class.call(email: onboarded_user.email, password: password)
        expect(result.data[:onboarding_completed]).to be true
      end
    end
  end
end

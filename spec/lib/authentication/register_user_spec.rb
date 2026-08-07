require "rails_helper"

RSpec.describe Authentication::RegisterUser do
  describe "#call" do
    let(:valid_params) do
      {
        name: "Jane Doe",
        email: "jane@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: "individual"
      }
    end

    it "creates a new user" do
      expect { described_class.call(**valid_params) }
        .to change(User, :count).by(1)
    end

    it "returns a successful Result" do
      result = described_class.call(**valid_params)
      expect(result).to be_success
    end

    it "returns user data" do
      result = described_class.call(**valid_params)
      expect(result.data[:name]).to eq("Jane Doe")
      expect(result.data[:email]).to eq("jane@example.com")
      expect(result.data[:role]).to eq("individual")
      expect(result.data[:verified]).to be false
    end

    it "creates an email verification token" do
      expect { described_class.call(**valid_params) }
        .to change(EmailVerificationToken, :count).by(1)
    end

    it "sends a verification email" do
      expect { described_class.call(**valid_params) }
        .to have_enqueued_mail(AuthenticationMailer, :verification)
    end

    context "with invalid role" do
      it "returns failure" do
        result = described_class.call(**valid_params.merge(role: "invalid"))
        expect(result).to be_failure
      end
    end

    context "with the deprecated adopter role" do
      it "normalizes it to an individual account" do
        result = described_class.call(**valid_params.merge(role: "adopter"))
        expect(result).to be_success
        expect(result.data[:role]).to eq("individual")
        expect(User.last.role).to eq("individual")
        expect(User.last).to be_individual
      end
    end

    context "with invalid params" do
      it "returns failure when passwords don't match" do
        result = described_class.call(**valid_params.merge(password_confirmation: "different"))
        expect(result).to be_failure
      end

      it "returns failure when email is invalid" do
        result = described_class.call(**valid_params.merge(email: "invalid"))
        expect(result).to be_failure
      end
    end

    context "with shelter_admin role" do
      it "creates user with shelter_admin role" do
        result = described_class.call(**valid_params.merge(role: "shelter_admin"))
        expect(result).to be_success
        expect(result.data[:role]).to eq("shelter_admin")
      end
    end
  end
end

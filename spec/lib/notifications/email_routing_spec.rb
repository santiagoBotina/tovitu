require "rails_helper"

RSpec.describe Notifications::EmailRouting do
  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter) }

  describe ".route_for" do
    context "request_submitted" do
      it "routes the adopter to request_confirmation" do
        message = described_class.route_for("request_submitted", request, adopter)
        expect(message.mailer_class).to eq(AdoptionMailer)
        expect(message.action).to eq(:request_confirmation)
      end

      it "routes shelter staff to new_request_notification" do
        staff = create(:user, :shelter_admin, shelter: shelter)
        message = described_class.route_for("request_submitted", request, staff)
        expect(message.mailer_class).to eq(AdoptionMailer)
        expect(message.action).to eq(:new_request_notification)
      end

      it "routes an individual publisher to new_request_notification" do
        publisher = create(:user, :verified, :onboarding_completed)
        pet.update!(publisher: publisher, shelter: nil)
        request.update!(shelter: nil)
        message = described_class.route_for("request_submitted", request, publisher)
        expect(message.action).to eq(:new_request_notification)
      end

      it "returns nil when notifiable is not an AdoptionRequest" do
        expect(described_class.route_for("request_submitted", pet, adopter)).to be_nil
      end
    end

    context "request status kinds" do
      %w[request_in_validation request_accepted request_declined].each do |kind|
        it "routes #{kind} to status_changed" do
          message = described_class.route_for(kind, request, adopter)
          expect(message.mailer_class).to eq(AdoptionMailer)
          expect(message.action).to eq(:status_changed)
        end
      end
    end

    context "request_withdrawn" do
      it "routes to request_withdrawn with the recipient" do
        staff = create(:user, :shelter_admin, shelter: shelter)
        message = described_class.route_for("request_withdrawn", request, staff)
        expect(message.mailer_class).to eq(AdoptionMailer)
        expect(message.action).to eq(:request_withdrawn)
      end
    end

    context "welcome" do
      it "routes to AuthenticationMailer#welcome" do
        message = described_class.route_for("welcome", adopter, adopter)
        expect(message.mailer_class).to eq(AuthenticationMailer)
        expect(message.action).to eq(:welcome)
      end
    end

    context "deferred kinds" do
      %w[message_received pet_status_changed info_requested info_received].each do |kind|
        it "returns nil for #{kind}" do
          expect(described_class.route_for(kind, request, adopter)).to be_nil
        end
      end
    end

    it "accepts symbol kinds" do
      message = described_class.route_for(:request_accepted, request, adopter)
      expect(message.action).to eq(:status_changed)
    end

    it "returns nil for unknown kinds" do
      expect(described_class.route_for("nope", request, adopter)).to be_nil
    end
  end
end

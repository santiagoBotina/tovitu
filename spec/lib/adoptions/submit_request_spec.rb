require "rails_helper"

RSpec.describe Adoptions::SubmitRequest do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:pet) { create(:pet, shelter: shelter) }
    let(:adopter) { create(:user, :verified, :onboarding_completed) }

    context "with valid params" do
      it "creates an adoption request" do
        expect {
          described_class.call(adopter: adopter, pet: pet)
        }.to change(AdoptionRequest, :count).by(1)
      end

      it "sets the status to pending" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result.data).to be_pending
      end

      it "creates a timeline event" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result.data.timeline_events.count).to eq(1)
        event = result.data.timeline_events.first
        expect(event.from_status).to be_nil
        expect(event.to_status).to eq("pending")
      end

      it "returns a successful result" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result).to be_success
        expect(result.data).to be_a(AdoptionRequest)
      end

      it "delivers notifications" do
        expect(Notifications::Deliver).to receive(:call).at_least(:once)
        described_class.call(adopter: adopter, pet: pet)
      end
    end

    context "with additional answers" do
      let(:answers) do
        {
          "interest_reason" => "I love this breed!",
          "home_description" => "I have a big yard.",
          "current_pets_details" => "No other pets.",
          "something_else" => "I work from home."
        }
      end

      it "stores sanitized additional answers" do
        result = described_class.call(adopter: adopter, pet: pet, additional_answers: answers)
        expect(result.data.additional_answers).to eq(answers)
      end

      it "filters out blank answers" do
        messy = answers.merge("something_else" => "")
        result = described_class.call(adopter: adopter, pet: pet, additional_answers: messy)
        expect(result.data.additional_answers).not_to have_key("something_else")
      end

      it "handles ActionController::Parameters" do
        params = ActionController::Parameters.new(answers)
        result = described_class.call(adopter: adopter, pet: pet, additional_answers: params)
        expect(result.data.additional_answers["interest_reason"]).to eq("I love this breed!")
      end
    end

    context "when adopter onboarding is incomplete" do
      let(:adopter) { create(:user, :verified) }

      it "returns failure" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("adoptions.requests.errors.onboarding_incomplete"))
      end

      it "does not create a request" do
        expect {
          described_class.call(adopter: adopter, pet: pet)
        }.not_to change(AdoptionRequest, :count)
      end
    end

    context "when pet is not available" do
      before { pet.update!(status: :adopted, adopted_at: Time.current) }

      it "returns failure" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("adoptions.requests.errors.pet_not_available"))
      end
    end

    context "when an active request already exists" do
      before { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter, status: :pending) }

      it "returns failure" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("adoptions.requests.errors.duplicate"))
      end
    end

    context "when a previous request was declined" do
      before { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter, status: :declined) }

      it "allows a new request" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result).to be_success
      end
    end

    context "when shelter is inactive" do
      let(:shelter) { create(:shelter, :inactive) }

      it "returns failure" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("adoptions.requests.errors.shelter_inactive"))
      end
    end

    context "when pet is published by an individual" do
      let(:publisher) { create(:user, :verified, :onboarding_completed) }
      let(:pet) { create(:pet, :individual_listed, publisher: publisher) }

      it "creates a request without a shelter" do
        result = described_class.call(adopter: adopter, pet: pet)
        expect(result).to be_success
        expect(result.data.shelter).to be_nil
      end
    end
  end
end

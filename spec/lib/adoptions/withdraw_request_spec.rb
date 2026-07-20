require "rails_helper"

RSpec.describe Adoptions::WithdrawRequest do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:pet) { create(:pet, shelter: shelter) }
    let(:adopter) { create(:user, :verified, :onboarding_completed) }
    let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter, status: :pending) }

    context "with a withdrawable request" do
      before do
        # Ensure shelter has staff to notify
        create(:user, :verified, :shelter_admin, shelter: shelter)
      end

      it "changes status to withdrawn" do
        expect {
          described_class.call(request: request, adopter: adopter)
        }.to change { request.reload.status }.from("pending").to("withdrawn")
      end

      it "sets withdrawn_at timestamp" do
        freeze_time do
          described_class.call(request: request, adopter: adopter)
          expect(request.reload.withdrawn_at).to be_within(1.second).of(Time.current)
        end
      end

      it "creates a timeline event" do
        expect {
          described_class.call(request: request, adopter: adopter)
        }.to change { request.timeline_events.count }.by(1)

        event = request.timeline_events.last
        expect(event.from_status).to eq("pending")
        expect(event.to_status).to eq("withdrawn")
        expect(event.actor).to eq(adopter)
        expect(event.metadata).to include("withdrawn_by" => "adopter")
      end

      it "returns a successful result" do
        result = described_class.call(request: request, adopter: adopter)
        expect(result).to be_success
        expect(result.data).to eq(request)
      end

      it "notifies the responsible party" do
        expect(Notifications::Deliver).to receive(:call).at_least(:once)
        described_class.call(request: request, adopter: adopter)
      end
    end

    context "when request cannot be withdrawn" do
      it "returns failure for accepted requests" do
        request.update!(status: :accepted)
        result = described_class.call(request: request, adopter: adopter)
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("adoptions.requests.errors.cannot_withdraw"))
      end

      it "returns failure for declined requests" do
        request.update!(status: :declined)
        result = described_class.call(request: request, adopter: adopter)
        expect(result).to be_failure
      end

      it "returns failure for already withdrawn requests" do
        request.update!(status: :withdrawn)
        result = described_class.call(request: request, adopter: adopter)
        expect(result).to be_failure
      end
    end

    context "when the adopter does not own the request" do
      let(:other_user) { create(:user, :verified, :onboarding_completed) }

      it "returns failure" do
        result = described_class.call(request: request, adopter: other_user)
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("adoptions.requests.errors.not_owner"))
      end

      it "does not change the status" do
        expect {
          described_class.call(request: request, adopter: other_user)
        }.not_to change { request.reload.status }
      end
    end

    context "when the responsible party is a shelter" do
      before do
        create(:user, :verified, :shelter_admin, shelter: shelter)
        create(:user, :verified, :shelter_staff, shelter: shelter)
      end

      it "notifies all shelter admins and staff" do
        expect(Notifications::Deliver).to receive(:call).exactly(2).times
        described_class.call(request: request, adopter: adopter)
      end
    end

    context "when the responsible party is an individual publisher" do
      let(:publisher) { create(:user, :verified, :onboarding_completed) }
      let(:pet) { create(:pet, :individual_listed, publisher: publisher) }
      let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: nil) }

      it "notifies the publisher" do
        expect(Notifications::Deliver).to receive(:call).once
        described_class.call(request: request, adopter: adopter)
      end
    end
  end
end

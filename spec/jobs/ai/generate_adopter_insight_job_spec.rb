require "rails_helper"

RSpec.describe Ai::GenerateAdopterInsightJob do
  include ActiveJob::TestHelper

  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter) }

  describe "#perform" do
    context "with a request_id" do
      it "runs the full analysis for the request's adopter" do
        expect(Ai::Adopter::Analysis).to receive(:call)
          .with(adopter: adopter, request: request)
          .and_return(Result.success(insight: "insight", pet_fit: "pet_fit"))

        described_class.perform_now(request_id: request.id)
      end

      it "raises when the analysis fails so ActiveJob can retry" do
        allow(Ai::Adopter::Analysis).to receive(:call)
          .and_return(Result.failure("API error"))

        expect {
          described_class.perform_now(request_id: request.id)
        }.to raise_error(RuntimeError, /API error/)
      end
    end

    context "with an adopter_id (signal refresh)" do
      it "runs the insight-only analysis" do
        expect(Ai::Adopter::Analysis).to receive(:call)
          .with(adopter: adopter)
          .and_return(Result.success(insight: "insight"))

        described_class.perform_now(adopter_id: adopter.id)
      end
    end
  end

  describe "enqueue hooks" do
    it "enqueues the job when an adoption request is created" do
      expect {
        create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter)
      }.to have_enqueued_job(Ai::GenerateAdopterInsightJob).with(request_id: an_instance_of(Integer))
    end

    it "enqueues the job when an adopter saves a pet" do
      expect {
        create(:saved_pet, user: adopter, pet: pet)
      }.to have_enqueued_job(Ai::GenerateAdopterInsightJob).with(adopter_id: adopter.id)
    end
  end
end

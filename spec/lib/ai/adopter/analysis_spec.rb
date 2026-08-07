require "rails_helper"

RSpec.describe Ai::Adopter::Analysis do
  include AiProviderStub

  subject(:service) { described_class.call(adopter: adopter, request: request) }

  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let!(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter) }

  before do
    allow(Ai::Adopter::InsightAnalyzer).to receive(:call).and_return(Result.success(default_adopter_insight_response))
    allow(Ai::Adopter::PetFitAnalyzer).to receive(:call).and_return(Result.success(default_pet_fit_response))
  end

  describe "#call" do
    it "returns a successful Result" do
      expect(service).to be_success
    end

    it "persists the cached Adopter Insight for the adopter" do
      expect { service }.to change(AdopterInsight, :count).by(1)
      insight = adopter.adopter_insight.reload
      expect(insight.data["archetype"]).to eq("active_outdoors_partner")
      expect(insight.signal_fingerprint).to be_present
      expect(insight.generated_at).to be_present
    end

    it "persists the Pet-Fit Summary on the request" do
      expect { service }.to change { request.reload.pet_fit_data }.from({})
      expect(request.pet_fit_data["summary"]).to be_present
      expect(request.pet_fit_fingerprint).to be_present
      expect(request.pet_fit_signal_fingerprint).to be_present
      expect(request.pet_fit_generated_at).to be_present
    end

    context "when the cached insight is already fresh" do
      let!(:existing) do
        AdopterInsight.create!(adopter: adopter, data: default_adopter_insight_response, generated_at: Time.current)
      end

      before do
        signals = Ai::Adopter::SignalCollector.call(adopter: adopter)
        existing.update!(signal_fingerprint: signals[:fingerprint])
      end

      it "reuses the cached insight without calling the analyzer" do
        expect(Ai::Adopter::InsightAnalyzer).not_to receive(:call)
        service
      end

      it "still generates the pet-fit summary" do
        expect(Ai::Adopter::PetFitAnalyzer).to receive(:call).once.and_return(Result.success(default_pet_fit_response))
        service
        expect(request.reload.pet_fit_data).to be_present
      end
    end

    context "when a signal changed" do
      let!(:existing) do
        AdopterInsight.create!(
          adopter: adopter,
          data: { "archetype" => "homebody_companion" },
          signal_fingerprint: "old-fingerprint",
          generated_at: Time.current
        )
      end

      it "regenerates the insight (stale fingerprint)" do
        expect(Ai::Adopter::InsightAnalyzer).to receive(:call).once.and_return(Result.success(default_adopter_insight_response))
        service
        expect(adopter.adopter_insight.reload.signal_fingerprint).not_to eq("old-fingerprint")
      end
    end

    context "when the insight is older than the TTL" do
      let!(:existing) do
        signals = Ai::Adopter::SignalCollector.call(adopter: adopter)
        AdopterInsight.create!(
          adopter: adopter,
          data: default_adopter_insight_response,
          signal_fingerprint: signals[:fingerprint],
          generated_at: 25.hours.ago
        )
      end

      it "regenerates the insight" do
        expect(Ai::Adopter::InsightAnalyzer).to receive(:call).once.and_return(Result.success(default_adopter_insight_response))
        service
      end
    end

    context "when the pet-fit is already current" do
      before do
        service # generate first
      end

      it "reuses the existing pet-fit and does not call the analyzer again" do
        expect(Ai::Adopter::PetFitAnalyzer).not_to receive(:call)
        described_class.call(adopter: adopter, request: request)
      end
    end

    context "when the analyzer fails" do
      before do
        allow(Ai::Adopter::InsightAnalyzer).to receive(:call).and_return(Result.failure("API error"))
      end

      it "returns a failed Result" do
        expect(service).to be_failure
      end

      it "does not persist a pet-fit" do
        service
        expect(request.reload.pet_fit_data).to be_blank
      end
    end
  end

  describe "insight-only path (no request)" do
    subject(:service) { described_class.call(adopter: adopter) }

    it "generates the adopter insight without touching any request" do
      expect { service }.to change(AdopterInsight, :count).by(1)
      expect(service.data[:pet_fit]).to be_nil
    end
  end
end

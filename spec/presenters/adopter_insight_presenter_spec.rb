require "rails_helper"

RSpec.describe AdopterInsightPresenter do
  include AiProviderStub

  subject(:presenter) { described_class.new(request: request, adopter: adopter) }

  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter) }

  let(:insight_record) do
    AdopterInsight.create!(
      adopter: adopter,
      data: default_adopter_insight_response.merge(
        "self_reported_personality" => "calm_thoughtful",
        "archetype_diverges" => true,
        "provenance" => {
          "sources" => [ "onboarding answers" ],
          "based_on" => "onboarding answers",
          "activity_up_to" => Date.current.iso8601
        }
      ),
      generated_at: Time.current
    )
  end

  before do
    insight_record
    request.update!(pet_fit_data: default_pet_fit_response)
  end

  describe "state" do
    it "is ready when both the insight and the pet-fit exist" do
      expect(presenter.ready?).to be(true)
      expect(presenter.loading?).to be(false)
    end

    it "is loading when the request is recent but data is missing" do
      request.update!(pet_fit_data: {})
      AdopterInsight.where(adopter: adopter).delete_all
      expect(presenter.ready?).to be(false)
      expect(presenter.loading?).to be(true)
    end

    it "is unavailable when the data is missing and the request is old" do
      request.update!(pet_fit_data: {}, created_at: 1.day.ago)
      AdopterInsight.where(adopter: adopter).delete_all
      expect(presenter.ready?).to be(false)
      expect(presenter.loading?).to be(false)
      expect(presenter.unavailable?).to be(true)
    end
  end

  describe "archetype" do
    it "translates the archetype label" do
      expect(presenter.archetype_label).to eq("Active Outdoors Partner")
    end

    it "shows the self-report label" do
      expect(presenter.self_report_label).to eq("Calm and thoughtful")
    end

    it "flags when self-report and behavior diverge" do
      expect(presenter.diverges?).to be(true)
    end
  end

  describe "fit indicators" do
    it "builds translated indicators for all dimensions" do
      indicators = presenter.fit_indicators
      expect(indicators.size).to eq(5)
      energy = indicators.find { |i| i[:key] == "energy" }
      expect(energy[:label]).to eq("Energy match")
      expect(energy[:status]).to eq("strong_fit")
      expect(energy[:status_label]).to eq("Strong fit")
      expect(energy[:evidence]).to be_present
    end

    it "shows a translated not-enough-activity message for unknown dimensions without evidence" do
      request.update!(pet_fit_data: default_pet_fit_response.deep_merge(
        "fit_indicators" => { "household" => { "status" => "unknown", "evidence" => "" } }
      ))
      indicator = presenter.fit_indicators.find { |i| i[:key] == "household" }
      expect(indicator[:status_label]).to eq("Unknown")
      expect(indicator[:evidence]).to eq("Not enough activity yet")
    end
  end

  describe "commitment signals" do
    it "translates known signal labels and keeps observations" do
      signals_data = presenter.commitment_signals
      expect(signals_data.first[:label]).to eq("Follow-through")
      expect(signals_data.first[:observation]).to include("Applied to 1 pet")
    end

    it "falls back to a humanized label for unknown signal labels without raising" do
      insight_record.update!(data: insight_record.data.merge(
        "commitment_signals" => [
          { "label" => "applied.to.six.pets", "observation" => "Applied broadly.", "kind" => "neutral" }
        ]
      ))
      labels = presenter.commitment_signals.map { |s| s[:label] }
      expect(labels).to eq([ "Applied.to.six.pets" ])
    end
  end

  describe "pet-fit content" do
    it "exposes the summary and verification questions" do
      expect(presenter.summary).to include("strong match")
      expect(presenter.verification_questions).to include("Have you owned a dog before?")
    end
  end

  describe "confidence" do
    it "takes the most conservative of insight and pet-fit confidence" do
      request.update!(pet_fit_data: default_pet_fit_response.merge("confidence" => "low"))
      expect(presenter.confidence_key).to eq("low")
      expect(presenter.confidence_label).to eq("Low")
    end

    it "falls back when only the insight confidence exists" do
      request.update!(pet_fit_data: default_pet_fit_response.except("confidence"))
      expect(presenter.confidence_key).to eq("medium")
    end
  end

  describe "provenance" do
    it "exposes based_on and activity_up_to" do
      expect(presenter.based_on).to include("onboarding answers")
      expect(presenter.activity_up_to).to eq(Date.current.iso8601)
    end
  end
end

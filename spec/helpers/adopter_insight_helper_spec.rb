require "rails_helper"

RSpec.describe AdopterInsightHelper do
  include AdopterInsightHelper

  describe "#adopter_insight_icon" do
    it "renders a Lucide-style stroke svg with the requested classes" do
      html = adopter_insight_icon(:bolt, size: "w-5 h-5", extra_class: "text-primary-500")
      expect(html).to include("<svg")
      expect(html).to include("class=\"w-5 h-5 text-primary-500\"")
      expect(html).to include("fill=\"none\"")
      expect(html).to include("stroke=\"currentColor\"")
      expect(html).to include("stroke-width=\"2\"")
      expect(html).to include("viewBox=\"0 0 24 24\"")
      expect(html).to include("aria-hidden=\"true\"")
      expect(html).to include("<path")
    end

    it "returns an empty string for unknown icons instead of raising" do
      expect(adopter_insight_icon(:does_not_exist)).to eq("")
    end
  end

  describe "icon maps" do
    it "maps every known dimension to an icon" do
      Ai::Adopter::PetFitAnalyzer::DIMENSIONS.each do |dimension|
        expect(adopter_insight_factor_icon(dimension)).to include("svg")
      end
    end

    it "falls back to the default factor icon for unknown dimensions" do
      expect(adopter_insight_factor_icon("unknown_dimension")).to include("svg")
    end

    it "maps every archetype key to an icon and falls back for unknown keys" do
      Ai::Adopter::Archetype::KEYS.each do |key|
        expect(adopter_insight_archetype_icon(key.to_s)).to include("svg")
      end
      expect(adopter_insight_archetype_icon(nil)).to include("svg")
      expect(adopter_insight_archetype_icon("unknown")).to include("svg")
    end

    it "maps every signal kind to an icon and falls back for unknown kinds" do
      %w[positive attention neutral].each do |kind|
        expect(adopter_insight_signal_icon(kind)).to include("svg")
      end
      expect(adopter_insight_signal_icon("mystery")).to include("svg")
    end
  end

  describe "tint maps" do
    it "returns a known tint class for every fit status" do
      expect(adopter_insight_status_tint("strong_fit")).to eq("bg-secondary-50 text-secondary-700")
      expect(adopter_insight_status_tint("possible_mismatch")).to eq("bg-warning/10 text-warning")
      expect(adopter_insight_status_tint("unknown")).to eq("bg-neutral-100 text-neutral-500")
      expect(adopter_insight_status_tint("bogus")).to eq("bg-neutral-100 text-neutral-500")
    end

    it "returns a known tint class for every signal kind" do
      expect(adopter_insight_signal_tint("positive")).to eq("bg-secondary-50 text-secondary-700")
      expect(adopter_insight_signal_tint("attention")).to eq("bg-warning/10 text-warning")
      expect(adopter_insight_signal_tint("neutral")).to eq("bg-neutral-100 text-neutral-500")
    end
  end

  describe "truncation thresholds" do
    it "flags evidence longer than the expand threshold" do
      expect(adopter_insight_evidence_long?("x" * 111)).to be(true)
      expect(adopter_insight_evidence_long?("x" * 110)).to be(false)
    end

    it "flags summaries longer than the expand threshold" do
      expect(adopter_insight_summary_long?("x" * 141)).to be(true)
      expect(adopter_insight_summary_long?("x" * 140)).to be(false)
    end
  end
end

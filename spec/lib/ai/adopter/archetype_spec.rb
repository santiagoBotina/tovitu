require "rails_helper"

RSpec.describe Ai::Adopter::Archetype do
  describe "taxonomy" do
    it "exposes stable, i18n-friendly keys" do
      expect(described_class::KEYS).to include(
        :active_outdoors_partner, :homebody_companion, :first_time_parent,
        :experienced_guardian, :family_builder, :routine_keeper,
        :spontaneous_spirit, :social_house
      )
    end

    it "keeps the prompt taxonomy aligned with the keys" do
      described_class.prompt_taxonomy.lines.each do |line|
        key = line.strip.sub(/\A- /, "").split(":").first.strip
        expect(described_class::KEYS).to include(key.to_sym)
      end
    end
  end

  describe ".valid_key?" do
    it "returns true for a known key" do
      expect(described_class.valid_key?("homebody_companion")).to be(true)
    end

    it "returns false for an unknown key" do
      expect(described_class.valid_key?("mystery_archetype")).to be(false)
      expect(described_class.valid_key?(nil)).to be(false)
    end

    it "returns false for non-string values (defensive against malformed AI output)" do
      expect(described_class.valid_key?(123)).to be(false)
      expect(described_class.valid_key?(%w[active_outdoors_partner])).to be(false)
    end
  end

  describe ".label_key" do
    it "returns the locale key for a known archetype" do
      expect(described_class.label_key("family_builder")).to eq("ai.adopter_insight.archetypes.family_builder")
    end

    it "falls back to the unknown key for blank input" do
      expect(described_class.label_key(nil)).to eq("ai.adopter_insight.archetypes.unknown")
    end
  end
end

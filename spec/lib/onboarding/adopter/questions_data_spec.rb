require "rails_helper"

RSpec.describe Onboarding::Adopter::QuestionsData do
  describe ".all" do
    it "returns 8 questions" do
      expect(described_class.all.size).to eq(8)
    end

    it "includes question types" do
      types = described_class.all.map { |q| q[:type] }
      expect(types).to include("multi_select", "single_select", "text")
    end
  end

  describe ".find" do
    it "finds by number" do
      question = described_class.find(1)
      expect(question[:key]).to eq("weekend_activity")
    end

    it "returns nil for invalid number" do
      expect(described_class.find(99)).to be_nil
    end
  end

  describe ".count" do
    it "returns 8" do
      expect(described_class.count).to eq(8)
    end
  end
end

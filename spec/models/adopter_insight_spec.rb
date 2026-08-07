require "rails_helper"

RSpec.describe AdopterInsight do
  subject(:insight) do
    described_class.create!(adopter: adopter, data: { "archetype" => "family_builder" }, generated_at: Time.current)
  end

  let(:adopter) { create(:user, :verified, :onboarding_completed) }

  describe "associations" do
    it { is_expected.to belong_to(:adopter).class_name("User") }

    it "is destroyed when the adopter account is deleted (AC7 redaction)" do
      insight
      expect { adopter.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe "#fresh_for?" do
    it "is true when fingerprint matches and within TTL" do
      insight.update!(signal_fingerprint: "abc123")
      expect(insight.fresh_for?("abc123")).to be(true)
    end

    it "is false when the fingerprint differs" do
      insight.update!(signal_fingerprint: "abc123")
      expect(insight.fresh_for?("different")).to be(false)
    end

    it "is false when older than the TTL" do
      insight.update!(signal_fingerprint: "abc123", generated_at: 25.hours.ago)
      expect(insight.fresh_for?("abc123")).to be(false)
    end

    it "is false when never generated" do
      insight.update!(generated_at: nil)
      expect(insight.fresh_for?("abc123")).to be(false)
    end
  end

  describe "data" do
    it "defaults to an empty hash" do
      record = described_class.create!(adopter: adopter)
      expect(record.data).to eq({})
    end
  end

  describe "scopes" do
    it "finds fresh insights" do
      insight.update!(generated_at: Time.current)
      old = described_class.create!(adopter: create(:user), generated_at: 25.hours.ago)
      expect(described_class.fresh).to include(insight)
      expect(described_class.fresh).not_to include(old)
    end
  end
end

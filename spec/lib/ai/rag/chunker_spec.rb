require "rails_helper"

RSpec.describe Ai::Rag::Chunker do
  describe ".call" do
    context "with empty or nil text" do
      it "returns empty array for empty string" do
        expect(described_class.call("")).to eq([])
      end

      it "returns empty array for nil" do
        expect(described_class.call(nil)).to eq([])
      end

      it "returns empty array for blank string" do
        expect(described_class.call("   ")).to eq([])
      end
    end

    context "with short text (under TARGET_SIZE)" do
      it "returns a single chunk" do
        text = "Short text under 1000 characters."
        result = described_class.call(text)

        expect(result.size).to eq(1)
        expect(result.first[:content]).to eq(text)
        expect(result.first[:index]).to eq(0)
      end
    end

    context "with long text" do
      it "splits into multiple chunks" do
        text = ("Hello world. " * 150)
        result = described_class.call(text)

        expect(result.size).to be > 1
      end

      it "returns chunks with sequential indexes" do
        text = ("Hello world. " * 150)
        result = described_class.call(text)

        indexes = result.map { |c| c[:index] }
        expect(indexes).to eq((0...result.size).to_a)
      end

      it "contains overlap between consecutive chunks" do
        text = ("This is a test paragraph with enough text to create multiple chunks. " * 100)
        result = described_class.call(text)

        expect(result.size).to be > 1
        chunk0_tail = result[0][:content][-150..]
        chunk1_head = result[1][:content][0..150]
        overlap = (chunk0_tail.split & chunk1_head.split).first
        expect(overlap).not_to be_nil
      end
    end

    context "with metadata" do
      it "passes metadata through to each chunk" do
        metadata = { shelter_id: 42, source_type: "manual" }
        text = ("Hello world. " * 100)
        result = described_class.call(text, metadata: metadata)

        expect(result).to all(satisfy { |c| c[:metadata] == metadata })
      end
    end

    context "boundary detection" do
      it "respects paragraph boundaries when they align near chunk target" do
        p1 = "A" * 850
        p2 = "B" * 500
        text = "#{p1}\n\n#{p2}"

        result = described_class.call(text)

        expect(result.size).to eq(2)
        expect(result[0][:content]).to include("A" * 10)
        expect(result[1][:content]).to include("B" * 10)
      end

      it "respects sentence boundaries when no paragraph breaks exist" do
        sentences = (1..20).map { |i| "This is sentence number #{i} in a longer document about shelter adoption policies. " }
        text = sentences.join
        result = described_class.call(text)

        expect(result.size).to be > 1
        result.each do |chunk|
          expect(chunk[:content]).to be_present
        end
      end

      it "falls back to word boundaries" do
        words = ([ "longword" ] * 300).join(" ")
        text = words
        result = described_class.call(text)

        expect(result.size).to be > 1
        result.each do |chunk|
          expect(chunk[:content]).to be_present
        end
      end
    end

    context "with extremely long text" do
      it "limits to max 100 chunks" do
        text = "A" * 100_000
        result = described_class.call(text)

        expect(result.size).to be <= 100
      end
    end
  end
end

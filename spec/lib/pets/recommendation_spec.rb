require "rails_helper"

RSpec.describe Pets::Recommendation do
  describe ".sanitize" do
    it "returns nil for blank input" do
      expect(described_class.sanitize(nil)).to be_nil
      expect(described_class.sanitize("")).to be_nil
      expect(described_class.sanitize("   \n\t ")).to be_nil
    end

    it "strips script blocks entirely" do
      expect(described_class.sanitize("<script>alert('xss')</script>Hello"))
        .to eq("Hello")
    end

    it "strips style/iframe/object/embed blocks" do
      html = "<style>body{}</style><iframe src='x'></iframe><object></object><embed>ok text</embed>Text"
      expect(described_class.sanitize(html)).to eq("Text")
    end

    it "strips inline tags and event handlers" do
      html = '<img src="x" onerror="alert(1)"><a href="#">Click</a>'
      expect(described_class.sanitize(html)).to eq("Click")
      expect(described_class.sanitize(html)).not_to include("onerror")
    end

    it "neutralizes javascript:/vbscript:/data: URL schemes" do
      expect(described_class.sanitize('See <a href="javascript:alert(1)">this</a>')).to eq("See this")
      expect(described_class.sanitize('vbscript:msgbox(1) link')).not_to include("vbscript:")
    end

    it "decodes then re-strips entity-encoded markup" do
      expect(described_class.sanitize("&lt;script&gt;alert(1)&lt;/script&gt;fine")).to eq("fine")
    end

    it "removes comments" do
      expect(described_class.sanitize("keep<!-- nope -->text")).to eq("keep text")
    end

    it "collapses runs of whitespace" do
      expect(described_class.sanitize("a    b\t\tc")).to eq("a b c")
    end

    it "binds the result to MAX_LENGTH" do
      result = described_class.sanitize("x" * (described_class::MAX_LENGTH + 50))
      expect(result.length).to eq(described_class::MAX_LENGTH)
    end

    it "preserves line breaks" do
      expect(described_class.sanitize("line one\nline two")).to eq("line one\nline two")
    end
  end

  describe ".inappropriate?" do
    it "is false for blank input" do
      expect(described_class.inappropriate?(nil)).to be(false)
      expect(described_class.inappropriate?("")).to be(false)
    end

    it "flags blocklisted profanity" do
      expect(described_class.inappropriate?("This is shit")).to be(true)
      expect(described_class.inappropriate?("complete mierda")).to be(true)
    end

    it "flags leetspeak-obfuscated profanity" do
      expect(described_class.inappropriate?("sh1t")).to be(true)
      expect(described_class.inappropriate?("m1erda")).to be(true)
    end

    it "does not flag ordinary words that merely contain blocklist letters" do
      expect(described_class.inappropriate?("This is a very special pet")).to be(false)
      expect(described_class.inappropriate?("Sheep and shirts are fine")).to be(false)
    end

    it "allows warm, legitimate copy" do
      expect(described_class.appropriate?("Luna is a calm, sweet companion for a quiet home.")).to be(true)
    end
  end
end

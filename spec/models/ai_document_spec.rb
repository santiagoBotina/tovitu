require "rails_helper"

RSpec.describe Ai::Document, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shelter) }
    it { is_expected.to have_many(:chunks).dependent(:destroy) }
    it { is_expected.to have_one_attached(:file) }
  end

  describe "validations" do
    subject { build(:ai_document) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_inclusion_of(:source_type).in_array(%w[manual pdf]) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[processing ready failed]) }
  end

  describe "scopes" do
    let(:shelter) { create(:shelter) }
    let!(:ready_doc) { create(:ai_document, shelter: shelter, status: "ready") }
    let!(:processing_doc) { create(:ai_document, shelter: shelter, status: "processing") }

    it "ready" do
      expect(Ai::Document.ready).to include(ready_doc)
      expect(Ai::Document.ready).not_to include(processing_doc)
    end

    it "for_shelter" do
      other_shelter = create(:shelter)
      other_doc = create(:ai_document, shelter: other_shelter)
      expect(Ai::Document.for_shelter(shelter.id)).to include(ready_doc, processing_doc)
      expect(Ai::Document.for_shelter(shelter.id)).not_to include(other_doc)
    end
  end
end

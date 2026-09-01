require "rails_helper"

RSpec.describe Adoptions::RequestIndex do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let!(:requests) { create_list(:adoption_request, 3, shelter: shelter, pet: pet) }

  describe "#call" do
    it "returns a Result with records, page, per_page and has_next" do
      result = described_class.call(scope: AdoptionRequest.all)

      expect(result).to be_a(Adoptions::RequestIndex::Result)
      expect(result.records).to match_array(requests)
      expect(result.page).to eq(1)
      expect(result.per_page).to eq(Adoptions::RequestIndex::DEFAULT_PAGE_SIZE)
      expect(result.has_next).to be(false)
    end

    it "slices to a single page" do
      result = described_class.call(scope: AdoptionRequest.all, params: { page: 1, per_page: 2 })

      expect(result.records.size).to eq(2)
      expect(result.has_next).to be(true)

      page_two = described_class.call(scope: AdoptionRequest.all, params: { page: 2, per_page: 2 })
      expect(page_two.records.size).to eq(1)
      expect(page_two.has_next).to be(false)
    end

    it "never goes below page 1" do
      result = described_class.call(scope: AdoptionRequest.all, params: { page: -3, per_page: 2 })

      expect(result.page).to eq(1)
      expect(result.records.size).to eq(2)
    end

    it "clamps per_page to the allowed bounds" do
      oversized = described_class.call(scope: AdoptionRequest.all, params: { page: 1, per_page: 500 })
      expect(oversized.per_page).to eq(Adoptions::RequestIndex::MAX_PER_PAGE)

      undersized = described_class.call(scope: AdoptionRequest.all, params: { page: 1, per_page: 0 })
      expect(undersized.per_page).to eq(1)
    end

    it "eager-loads the associations the row rendering touches" do
      pet.photos.attach(
        io: Rails.root.join("spec/fixtures/files/valid_photo.jpg").open,
        filename: "valid_photo.jpg",
        content_type: "image/jpeg"
      )

      result = described_class.call(scope: AdoptionRequest.all)

      record = result.records.first
      expect(record.association(:adopter)).to be_loaded
      expect(record.association(:shelter)).to be_loaded
      expect(record.association(:pet)).to be_loaded
      expect(record.pet.association(:photos_attachments)).to be_loaded
      expect(record.pet.photos_attachments.first.association(:blob)).to be_loaded
    end
  end
end

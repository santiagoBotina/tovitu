require "rails_helper"

RSpec.describe Pets::PhotoManager do
  describe ".attach" do
    let(:pet) { create(:pet) }
    let(:photo) { fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg") }

    it "attaches a photo" do
      result = described_class.attach(pet: pet, file: photo)
      expect(result).to be_success
      expect(pet.reload.photos).to be_attached
    end

    it "updates photo_order" do
      expect { described_class.attach(pet: pet, file: photo) }
        .to change { pet.reload.photo_order }
    end

    it "enqueues variant pre-generation for the attached blob" do
      expect { described_class.attach(pet: pet, file: photo) }
        .to have_enqueued_job(Pets::GeneratePhotoVariantsJob)
    end

    context "with invalid content type" do
      let(:gif) { fixture_file_upload("spec/fixtures/files/valid_photo.gif", "image/gif") }

      it "returns failure" do
        result = described_class.attach(pet: pet, file: gif)
        expect(result).to be_failure
      end
    end
  end

  describe ".primary" do
    let(:pet) { create(:pet) }

    it "returns nil when no photos" do
      expect(described_class.primary(pet: pet)).to be_nil
    end
  end

  describe ".attach_many" do
    let(:pet) { create(:pet) }
    let(:jpg) { fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg") }
    let(:jpg2) { fixture_file_upload("spec/fixtures/files/valid_photo_2.jpg", "image/jpeg") }
    let(:gif) { fixture_file_upload("spec/fixtures/files/valid_photo.gif", "image/gif") }

    it "attaches multiple valid files" do
      result = described_class.attach_many(pet: pet, files: [ jpg, jpg2 ])

      expect(result).to be_success
      expect(pet.reload.photos.count).to eq(2)
      expect(pet.photo_order.length).to eq(2)
    end

    it "enqueues variant pre-generation for each attached blob" do
      expect { described_class.attach_many(pet: pet, files: [ jpg, jpg2 ]) }
        .to have_enqueued_job(Pets::GeneratePhotoVariantsJob).twice
    end

    it "attaches valid files and reports per-file errors without breaking the batch" do
      result = described_class.attach_many(pet: pet, files: [ jpg, gif ])

      expect(result).to be_success
      expect(pet.reload.photos.count).to eq(1)
      expect(result.errors).to include(I18n.t("pets.errors.photos.invalid_type"))
    end

    it "returns failure when no files are valid" do
      result = described_class.attach_many(pet: pet, files: [ gif ])

      expect(result).to be_failure
      expect(pet.reload.photos).not_to be_attached
    end

    it "respects the maximum photo count across the batch" do
      10.times do
        file = fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg")
        described_class.attach_many(pet: pet, files: [ file ])
      end

      result = described_class.attach_many(pet: pet, files: [ jpg, jpg2 ])

      expect(result).to be_success
      expect(pet.reload.photos.count).to eq(10)
      expect(result.errors).to include(I18n.t("pets.errors.photos.max_count"))
    end
  end

  describe ".attach_by_url" do
    let(:pet) { create(:pet) }

    def http_response(status:, content_type:, body:)
      double(code: status, success?: (200..299).cover?(status), headers: { "content-type" => content_type }, body: body)
    end

    it "fetches and attaches an image from a URL" do
      allow(HTTParty).to receive(:get).and_return(
        http_response(
          status: 200,
          content_type: "image/jpeg",
          body: File.binread(Rails.root.join("spec/fixtures/files/valid_photo.jpg"))
        )
      )

      result = described_class.attach_by_url(pet: pet, url: "https://example.com/pet.jpg")

      expect(result).to be_success
      expect(pet.reload.photos).to be_attached
    end

    it "rejects a URL that is not an image" do
      allow(HTTParty).to receive(:get).and_return(
        http_response(status: 200, content_type: "text/html", body: "<html></html>")
      )

      result = described_class.attach_by_url(pet: pet, url: "https://example.com/page")

      expect(result).to be_failure
      expect(result.errors).to include(I18n.t("pets.errors.photos.invalid_type"))
      expect(pet.reload.photos).not_to be_attached
    end

    it "rejects an unreachable URL" do
      allow(HTTParty).to receive(:get).and_return(http_response(status: 404, content_type: "text/html", body: "nope"))

      result = described_class.attach_by_url(pet: pet, url: "https://example.com/missing.jpg")

      expect(result).to be_failure
      expect(result.errors).to include(I18n.t("pets.errors.photos.url_unreachable"))
    end

    it "rejects a blank URL" do
      result = described_class.attach_by_url(pet: pet, url: " ")

      expect(result).to be_failure
      expect(result.errors).to include(I18n.t("pets.errors.photos.url_invalid"))
    end
  end

  describe ".set_primary" do
    let(:pet) { create(:pet) }

    before do
      described_class.attach_many(
        pet: pet,
        files: [
          fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg"),
          fixture_file_upload("spec/fixtures/files/valid_photo_2.jpg", "image/jpeg")
        ]
      )
    end

    it "moves the target photo to the front of the order" do
      second = pet.reload.photos.second

      result = described_class.set_primary(pet: pet, blob_id: second.blob_id)

      expect(result).to be_success
      expect(pet.reload.primary_photo.blob_id).to eq(second.blob_id)
    end

    it "returns failure for an unknown photo" do
      result = described_class.set_primary(pet: pet, blob_id: 999_999)

      expect(result).to be_failure
    end
  end

  describe ".move" do
    let(:pet) { create(:pet) }

    before do
      described_class.attach_many(
        pet: pet,
        files: [
          fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg"),
          fixture_file_upload("spec/fixtures/files/valid_photo_2.jpg", "image/jpeg")
        ]
      )
    end

    it "moves a photo down and up" do
      first = pet.reload.photos.first
      second = pet.reload.photos.second

      expect(described_class.move(pet: pet, blob_id: first.blob_id, direction: :down)).to be_success
      expect(pet.reload.primary_photo.blob_id).to eq(second.blob_id)

      expect(described_class.move(pet: pet, blob_id: first.blob_id, direction: :up)).to be_success
      expect(pet.reload.primary_photo.blob_id).to eq(first.blob_id)
    end

    it "fails when moving the first photo up" do
      first = pet.reload.photos.first

      result = described_class.move(pet: pet, blob_id: first.blob_id, direction: :up)

      expect(result).to be_failure
    end
  end

  describe ".detach primary fallback" do
    let(:pet) { create(:pet) }

    it "falls back to the next photo when the primary is deleted" do
      described_class.attach_many(
        pet: pet,
        files: [
          fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg"),
          fixture_file_upload("spec/fixtures/files/valid_photo_2.jpg", "image/jpeg")
        ]
      )
      primary = pet.reload.primary_photo

      described_class.detach(pet: pet, blob_id: primary.blob_id)

      expect(pet.reload.primary_photo).to be_present
      expect(pet.primary_photo.blob_id).not_to eq(primary.blob_id)
    end
  end
end

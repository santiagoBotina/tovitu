require "rails_helper"

RSpec.describe Shelter, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:invitations).dependent(:destroy) }
    it { is_expected.to have_many(:pets).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:adoption_applications).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:ai_documents).dependent(:destroy) }
    it { is_expected.to have_one_attached(:logo) }
    it { is_expected.to have_one_attached(:cover_image) }
    it { is_expected.to have_one_attached(:profile_picture) }
  end

  describe "validations" do
    subject { build(:shelter) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_presence_of(:street) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:zip) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_presence_of(:species_served) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active inactive]) }
  end

  describe "scopes" do
    let!(:active_shelter) { create(:shelter, status: "active") }
    let!(:inactive_shelter) { create(:shelter, status: "inactive") }
    let(:ai_shelter) { create(:shelter, ai_features_enabled: true) }

    it "active" do
      expect(Shelter.active).to include(active_shelter)
      expect(Shelter.active).not_to include(inactive_shelter)
    end

    it "inactive" do
      expect(Shelter.inactive).to include(inactive_shelter)
    end

    it "undiscarded" do
      discarded = create(:shelter, :discarded)
      expect(Shelter.undiscarded).to include(active_shelter, inactive_shelter)
      expect(Shelter.undiscarded).not_to include(discarded)
    end

    it "with_ai_features" do
      expect(Shelter.with_ai_features).to include(ai_shelter)
    end
  end

  describe "#ai_features_enabled?" do
    it "returns true by default" do
      shelter = build(:shelter)
      expect(shelter).to be_ai_features_enabled
    end

    it "returns false when explicitly disabled" do
      shelter = build(:shelter, :with_ai_disabled)
      expect(shelter).not_to be_ai_features_enabled
    end
  end

  describe "#active?" do
    it "returns true when active" do
      shelter = build(:shelter, status: "active")
      expect(shelter).to be_active
    end

    it "returns false when inactive" do
      shelter = build(:shelter, status: "inactive")
      expect(shelter).not_to be_active
    end
  end

  describe "#discard! / #undiscard! / #discarded?" do
    it "marks shelter as discarded" do
      shelter = create(:shelter)
      shelter.discard!
      expect(shelter).to be_discarded
    end

    it "restores a discarded shelter" do
      shelter = create(:shelter, :discarded)
      shelter.undiscard!
      expect(shelter).not_to be_discarded
    end
  end

  describe "species_served validation" do
    it "is invalid when not an array" do
      shelter = build(:shelter, species_served: "dog")
      shelter.valid?
      expect(shelter.errors[:species_served]).to include("must be an array")
    end
  end

  describe "image attachment validations" do
    let(:shelter) { create(:shelter) }

    it "rejects invalid content type for logo" do
      result = shelter.update(logo: {
        io: StringIO.new("not an image"),
        filename: "test.txt",
        content_type: "text/plain"
      })
      expect(shelter.errors[:logo]).to be_present
      expect(result).to be false
    end

    it "accepts valid image for logo" do
      expect(shelter.update(logo: {
        io: file_fixture("valid_photo.jpg").open,
        filename: "photo.jpg",
        content_type: "image/jpeg"
      })).to be true
    end
  end
end

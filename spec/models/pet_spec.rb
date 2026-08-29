require "rails_helper"

RSpec.describe Pet, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shelter).optional.touch(true) }
    it { is_expected.to have_many(:adoption_applications).dependent(:restrict_with_error) }
    it { is_expected.to have_many_attached(:photos) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:species) }
    it { is_expected.to validate_presence_of(:age_category) }
    it { is_expected.to validate_presence_of(:sex) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_length_of(:breed).is_at_most(100).allow_blank }
  end

  describe "enums" do
    it "defines species enum with prefix scopes" do
      pet = create(:pet, species: "cat")
      expect(pet).to be_species_cat
      expect(pet).not_to be_species_dog
    end

    it "supports all six species values" do
      expect(Pet::SPECIES).to eq(%w[dog cat bird rabbit hamster other])
    end

    it "defines an emoji for every supported species" do
      expect(Pet::SPECIES_EMOJI.keys).to match_array(Pet::SPECIES)
      expect(Pet::SPECIES_EMOJI["bird"]).to eq("🐦")
      expect(Pet::SPECIES_EMOJI["rabbit"]).to eq("🐰")
      expect(Pet::SPECIES_EMOJI["hamster"]).to eq("🐹")
    end

    it "keeps legacy 'other' pets valid and displayable" do
      pet = build(:pet, shelter: create(:shelter), species: "other")
      expect(pet).to be_valid
      expect(pet.species_other?).to be true
    end

    it "defines age categories enum with prefix scopes" do
      pet = create(:pet, age_category: "young")
      expect(pet).to be_age_category_young
    end

    it "defines sizes enum with prefix scopes" do
      pet = create(:pet, size: "large")
      expect(pet).to be_size_large
    end

    it "defines sexes enum with prefix scopes" do
      pet = create(:pet, sex: "female")
      expect(pet).to be_sex_female
    end

    it "defines statuses enum with prefix scopes" do
      pet = create(:pet, status: "on_hold")
      expect(pet).to be_status_on_hold
    end
  end

  describe "scopes" do
    let(:shelter) { create(:shelter) }
    let!(:available_pet) { create(:pet, shelter: shelter, status: "available") }
    let!(:on_hold_pet) { create(:pet, shelter: shelter, status: "on_hold") }
    let!(:adopted_pet) { create(:pet, shelter: shelter, status: "adopted", adopted_at: Time.current) }
    let!(:not_available_pet) { create(:pet, shelter: shelter, status: "not_available") }
    let!(:removed_pet) { create(:pet, shelter: shelter, status: "removed") }
    let!(:discarded_pet) { create(:pet, shelter: shelter, status: "removed", discarded_at: Time.current) }

    it "available" do
      expect(Pet.available).to include(available_pet)
      expect(Pet.available).not_to include(on_hold_pet, adopted_pet, not_available_pet, removed_pet, discarded_pet)
    end

    it "on_hold" do
      expect(Pet.on_hold).to include(on_hold_pet)
    end

    it "adopted" do
      expect(Pet.adopted).to include(adopted_pet)
    end

    it "not_available" do
      expect(Pet.not_available).to include(not_available_pet)
    end

    it "removed" do
      expect(Pet.removed).to include(removed_pet, discarded_pet)
    end

    it "undiscarded" do
      expect(Pet.undiscarded).to include(available_pet, on_hold_pet, adopted_pet, not_available_pet, removed_pet)
      expect(Pet.undiscarded).not_to include(discarded_pet)
    end

    it "visible excludes removed and not_available" do
      expect(Pet.visible).to include(available_pet, on_hold_pet, adopted_pet)
      expect(Pet.visible).not_to include(not_available_pet, removed_pet, discarded_pet)
    end

    it "searchable returns only available" do
      expect(Pet.searchable).to include(available_pet)
      expect(Pet.searchable).not_to include(on_hold_pet, adopted_pet, not_available_pet, removed_pet, discarded_pet)
    end

    it "by_shelter filters by shelter_id" do
      other_shelter = create(:shelter)
      other_pet = create(:pet, shelter: other_shelter)
      expect(Pet.by_shelter(shelter.id)).to include(available_pet)
      expect(Pet.by_shelter(shelter.id)).not_to include(other_pet)
    end
  end

  describe "#discard!" do
    it "marks pet as discarded and changes status to removed" do
      pet = create(:pet, status: "available")
      pet.discard!
      expect(pet).to be_discarded
      expect(pet.status).to eq("removed")
    end
  end

  describe "#undiscard!" do
    it "restores a discarded pet" do
      pet = create(:pet, :discarded)
      pet.undiscard!
      expect(pet).not_to be_discarded
    end
  end

  describe "#primary_photo" do
    let(:pet) { create(:pet) }

    it "returns nil when no photos" do
      expect(pet.primary_photo).to be_nil
    end
  end

  describe "#ordered_photos" do
    let(:pet) { create(:pet) }

    it "returns empty array when no photos" do
      expect(pet.ordered_photos).to eq([])
    end
  end

  describe "life preview" do
    let(:pet) { create(:pet) }

    describe "#life_preview_stale?" do
      it "returns true when life_preview_data is blank" do
        expect(pet.life_preview_stale?).to be true
      end

      it "returns true when version is zero" do
        pet.update_columns(life_preview_version: 0, life_preview_data: { "test" => "data" })
        expect(pet.life_preview_stale?).to be true
      end

      it "returns false when data exists and version matches" do
        pet.update_columns(life_preview_data: { "test" => "data", "locale" => "en" }, life_preview_version: Pet.current_life_preview_version)
        expect(pet.life_preview_stale?).to be false
      end

      it "returns true when the cached preview locale differs from the active locale" do
        pet.update_columns(life_preview_data: { "test" => "data", "locale" => "es" }, life_preview_version: Pet.current_life_preview_version)
        I18n.with_locale(:en) do
          expect(pet.life_preview_stale?).to be true
        end
      end

      it "returns false when the cached preview locale matches the active locale" do
        pet.update_columns(life_preview_data: { "test" => "data", "locale" => "es" }, life_preview_version: Pet.current_life_preview_version)
        I18n.with_locale(:es) do
          expect(pet.life_preview_stale?).to be false
        end
      end

      it "returns true when the cached preview has no locale (legacy data)" do
        pet.update_columns(life_preview_data: { "test" => "data" }, life_preview_version: Pet.current_life_preview_version)
        expect(pet.life_preview_stale?).to be true
      end
    end

    describe "#mark_life_preview_stale!" do
      it "sets version to zero" do
        pet.update_columns(life_preview_version: 2)
        pet.mark_life_preview_stale!
        expect(pet.life_preview_version).to be_zero
      end
    end

    describe "#clear_life_preview!" do
      it "clears preview data, generation time, and version" do
        pet.update_columns(life_preview_data: { "test" => "data" }, life_preview_generated_at: Time.current, life_preview_version: 2)
        pet.clear_life_preview!
        expect(pet.life_preview_data).to be_nil
        expect(pet.life_preview_generated_at).to be_nil
        expect(pet.life_preview_version).to be_zero
      end
    end
  end

  describe "birth_date validation" do
    let(:shelter) { create(:shelter) }

    it "is valid when birth_date matches age_category" do
      pet = build(:pet, shelter: shelter, age_category: "baby", birth_date: 2.months.ago)
      expect(pet).to be_valid
    end

    it "is invalid when birth_date does not match age_category" do
      pet = build(:pet, shelter: shelter, age_category: "baby", birth_date: 10.years.ago)
      expect(pet).not_to be_valid
      expect(pet.errors[:birth_date]).to be_present
    end
  end

  describe "callbacks" do
    describe "invalidate_life_preview_if_needed" do
      let(:pet) { create(:pet, :with_life_preview) }

      it "clears life preview when invalidating attributes change" do
        expect { pet.update!(description: "New description") }
          .to change { pet.life_preview_version }
      end

      it "does not clear life preview when irrelevant attributes change" do
        expect { pet.update!(name: "New Name") }
          .not_to change { pet.life_preview_version }
      end
    end
  end

  describe "recommendation" do
    let(:shelter) { create(:shelter) }

    it "is optional" do
      pet = build(:pet, shelter: shelter, recommendation: nil)
      expect(pet).to be_valid
    end

    it "sanitizes HTML and scripts on save (stores plain text)" do
      pet = create(:pet, shelter: shelter, recommendation: '<script>alert("xss")</script>Luna loves <b>quiet</b> homes.')
      expect(pet.reload.recommendation).to eq("Luna loves quiet homes.")
      expect(pet.recommendation).not_to include("<script")
      expect(pet.recommendation).not_to include("<b>")
    end

    it "strips event handlers and dangerous URL schemes" do
      pet = create(:pet, shelter: shelter, recommendation: '<img src=x onerror="alert(1)">Check <a href="javascript:alert(2)">this</a>')
      expect(pet.reload.recommendation).not_to include("onerror")
      expect(pet.reload.recommendation).not_to include("javascript:")
    end

    it "neutralizes entity-encoded markup" do
      pet = create(:pet, shelter: shelter, recommendation: "&lt;script&gt;alert(1)&lt;/script&gt; Fine text")
      expect(pet.reload.recommendation).to eq("Fine text")
    end

    it "stores whitespace-only input as nil (section hidden)" do
      pet = create(:pet, shelter: shelter, recommendation: "   \n\t  ")
      expect(pet.reload.recommendation).to be_nil
    end

    it "truncates over-long input to the maximum length" do
      pet = create(:pet, shelter: shelter, recommendation: "word " * 400)
      expect(pet).to be_valid
      expect(pet.reload.recommendation.length).to be <= Pets::Recommendation::MAX_LENGTH
    end

    it "rejects profanity with a friendly error" do
      pet = build(:pet, shelter: shelter, recommendation: "This pet is complete shit")
      expect(pet).not_to be_valid
      expect(pet.errors[:recommendation]).to include(I18n.t("pets.errors.recommendation_inappropriate"))
    end

    it "rejects leetspeak-obfuscated profanity" do
      pet = build(:pet, shelter: shelter, recommendation: "An absolute sh1t recommendation")
      expect(pet).not_to be_valid
    end

    it "allows legitimate warm copy" do
      pet = build(:pet, shelter: shelter, recommendation: "Luna is a sweet, calm companion who would thrive in a quiet home.")
      expect(pet).to be_valid
    end
  end
end

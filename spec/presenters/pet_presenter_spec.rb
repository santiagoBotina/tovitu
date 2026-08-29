require "rails_helper"

RSpec.describe PetPresenter do
  let(:shelter) { create(:shelter) }

  describe "#age_display" do
    context "when the pet has a birth date" do
      let(:pet) { create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago) }
      subject(:presenter) { described_class.new(pet) }

      it "renders the age unit in English" do
        I18n.with_locale(:en) do
          expect(presenter.age_display).to eq("Adult (5 years)")
        end
      end

      it "renders the age unit in Spanish" do
        I18n.with_locale(:es) do
          expect(presenter.age_display).to eq("Adulto (5 años)")
        end
      end

      it "keeps the numeric age identical across locales" do
        en_age = I18n.with_locale(:en) { presenter.age_display }
        es_age = I18n.with_locale(:es) { presenter.age_display }

        expect(en_age).to match(/\((\d+) /)
        expect(es_age).to match(/\((\d+) /)
        expect(en_age[/\((\d+) /, 1]).to eq(es_age[/\((\d+) /, 1])
      end
    end

    context "when the pet is 1 year old" do
      let(:pet) { create(:pet, shelter: shelter, age_category: "young", birth_date: 1.year.ago) }
      subject(:presenter) { described_class.new(pet) }

      it "uses the singular unit in English" do
        I18n.with_locale(:en) do
          expect(presenter.age_display).to eq("Young (1 year)")
        end
      end

      it "uses the singular unit in Spanish" do
        I18n.with_locale(:es) do
          expect(presenter.age_display).to eq("Joven (1 año)")
        end
      end
    end

    context "when the pet has no birth date" do
      let(:pet) { create(:pet, shelter: shelter, age_category: "senior", birth_date: nil) }
      subject(:presenter) { described_class.new(pet) }

      it "renders only the localized category in English" do
        I18n.with_locale(:en) do
          expect(presenter.age_display).to eq("Senior")
        end
      end

      it "renders only the localized category in Spanish" do
        I18n.with_locale(:es) do
          expect(presenter.age_display).to eq("Senior")
        end
      end
    end
  end

  describe "#species_emoji" do
    it "returns the matching emoji for every supported species" do
      Pet::SPECIES.each do |species|
        pet = create(:pet, shelter: shelter, species: species)
        expect(described_class.new(pet).species_emoji).to eq(Pet::SPECIES_EMOJI[species])
      end
    end

    it "falls back to the generic paw emoji for an unknown species" do
      pet = create(:pet, shelter: shelter, species: "dog")
      allow(pet).to receive(:species).and_return("dragon")
      expect(described_class.new(pet).species_emoji).to eq(Pet::SPECIES_EMOJI["other"])
    end
  end

  describe "#primary_photo_url" do
    let(:pet) { create(:pet, shelter: shelter) }

    context "when the pet has a photo" do
      before do
        pet.photos.attach(io: File.open(Rails.root.join("spec/fixtures/files/valid_photo.jpg")), filename: "pet.jpg", content_type: "image/jpeg")
      end

      it "returns a proxy representation path with the canonical webp variant" do
        url = described_class.new(pet).primary_photo_url(variant: :medium)

        expect(url).to start_with("/rails/active_storage/representations/proxy/")

        # The variation key is signed; decode it to confirm the webp options.
        variation_key = url.split("/")[6]
        transformations = ActiveStorage.verifier.verify(variation_key, purpose: :variation)
        expect(transformations).to include("format" => "webp", "resize_to_limit" => [ 400, 400 ])
      end

      it "returns a blob path for svg photos" do
        pet.photos.first.blob.update!(content_type: "image/svg+xml")
        url = described_class.new(pet).primary_photo_url(variant: :medium)

        expect(url).to start_with("/rails/active_storage/blobs/")
      end
    end

    context "when the pet has no photo" do
      it "returns the placeholder data uri" do
        url = described_class.new(pet).primary_photo_url(variant: :medium)

        expect(url).to start_with("data:image/svg+xml")
      end
    end
  end

  describe "#variant_dimensions" do
    it "returns container-matching dimensions for each variant" do
      presenter = described_class.new(create(:pet, shelter: shelter))

      expect(presenter.variant_dimensions(:thumb)).to eq([ 150, 150 ])
      expect(presenter.variant_dimensions(:medium)).to eq([ 400, 300 ])
      expect(presenter.variant_dimensions(:large)).to eq([ 1200, 750 ])
    end
  end

  describe "#ideal_home_fit_list" do
    it "maps size and household fits to localized tags" do
      pet = create(:pet, shelter: shelter, size: "small",
                         good_with_children: true, good_with_dogs: false, good_with_cats: true)
      presenter = described_class.new(pet)

      I18n.with_locale(:en) do
        expect(presenter.ideal_home_fit_list).to eq([
          I18n.t("pets.show.compatibility_fit_apartment"),
          I18n.t("pets.show.compatibility_fit_kids"),
          I18n.t("pets.show.compatibility_fit_cats")
        ])
      end
    end

    it "localizes the tags in Spanish" do
      pet = create(:pet, shelter: shelter, size: "large", good_with_dogs: true)
      presenter = described_class.new(pet)

      I18n.with_locale(:es) do
        expect(presenter.ideal_home_fit_list).to eq([
          I18n.t("pets.show.compatibility_fit_spacious", locale: :es),
          I18n.t("pets.show.compatibility_fit_dogs", locale: :es)
        ])
      end
    end

    it "returns an empty list when no fit signals are set" do
      pet = create(:pet, shelter: shelter, size: nil)
      expect(described_class.new(pet).ideal_home_fit_list).to eq([])
    end
  end
end

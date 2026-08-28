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
end
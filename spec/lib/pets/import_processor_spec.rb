require "rails_helper"

RSpec.describe Pets::ImportProcessor do
  let(:shelter) { create(:shelter) }
  let(:user) { create(:user, :shelter_admin, shelter: shelter) }

  def row(values, row_number: 2)
    { row_number: row_number, values: values }
  end

  def valid_row(overrides = {})
    { "name" => "Rex", "species" => "dog", "age_category" => "young", "sex" => "male" }.merge(overrides)
  end

  describe "#call" do
    it "creates valid pets" do
      result = described_class.call(shelter: shelter, user: user, rows: [ row(valid_row) ])

      expect(result).to be_success
      expect(shelter.pets.undiscarded.count).to eq(1)
      expect(result.data[:imported]).to eq([ { row: 2, name: "Rex", id: shelter.pets.last.id } ])
      expect(result.data[:errors]).to be_empty
    end

    it "normalizes enum labels and booleans" do
      values = valid_row(
        "species" => "Perro", "spayed_neutered" => "sí", "vaccinated" => "no",
        "personality_traits" => "Friendly, Playful"
      )

      described_class.call(shelter: shelter, user: user, rows: [ row(values) ])

      pet = shelter.pets.last
      expect(pet.species).to eq("dog")
      expect(pet.spayed_neutered).to be(true)
      expect(pet.vaccinated).to be(false)
      expect(pet.personality_traits).to eq([ "Friendly", "Playful" ])
    end

    it "does not import photos (flat data only)" do
      described_class.call(shelter: shelter, user: user, rows: [ row(valid_row) ])

      expect(shelter.pets.last.photos).not_to be_attached
    end

    context "with invalid rows" do
      it "skips invalid rows without creating partial pets and reports per-field errors" do
        bad = valid_row("species" => "dragon", "sex" => "maybe")
        good = valid_row("name" => "Luna")

        result = described_class.call(shelter: shelter, user: user, rows: [ row(bad), row(good, row_number: 3) ])

        expect(shelter.pets.undiscarded.count).to eq(1)
        expect(shelter.pets.undiscarded.first.name).to eq("Luna")
        expect(result.data[:errors].length).to eq(1)
        error = result.data[:errors].first
        expect(error[:row]).to eq(2)
        expect(error[:fields].keys).to contain_exactly("species", "sex")
      end

      it "reports missing required fields" do
        result = described_class.call(shelter: shelter, user: user, rows: [ row(valid_row.merge("name" => " ")) ])

        expect(shelter.pets.undiscarded.count).to eq(0)
        expect(result.data[:errors].first[:fields].keys).to include("name")
      end

      it "reports birth_date/age_category mismatches through model validations" do
        result = described_class.call(
          shelter: shelter, user: user,
          rows: [ row(valid_row("birth_date" => "2024-03-01", "age_category" => "senior")) ]
        )

        expect(shelter.pets.undiscarded.count).to eq(0)
        expect(result.data[:errors].first[:fields].keys).to include("birth_date")
      end

      it "creates valid rows even when other rows fail" do
        result = described_class.call(
          shelter: shelter, user: user,
          rows: [ row(valid_row), row(valid_row("name" => nil), row_number: 3) ]
        )

        expect(shelter.pets.undiscarded.count).to eq(1)
        expect(result.data[:imported].length).to eq(1)
        expect(result.data[:errors].length).to eq(1)
      end
    end

    context "duplicate strategy (natural key: name + species + birth_date)" do
      it "skips rows duplicating an existing shelter pet" do
        create(:pet, shelter: shelter, name: "Rex", species: "dog", age_category: "young", birth_date: Date.new(2024, 3, 1))

        result = described_class.call(
          shelter: shelter, user: user,
          rows: [ row(valid_row("birth_date" => "2024-03-01")) ]
        )

        expect(shelter.pets.undiscarded.count).to eq(1)
        expect(result.data[:duplicates].length).to eq(1)
        expect(result.data[:imported]).to be_empty
      end

      it "skips duplicate rows within the same file" do
        result = described_class.call(
          shelter: shelter, user: user,
          rows: [ row(valid_row), row(valid_row, row_number: 3) ]
        )

        expect(shelter.pets.undiscarded.count).to eq(1)
        expect(result.data[:duplicates].length).to eq(1)
      end

      it "treats pets in other shelters as distinct" do
        other_shelter = create(:shelter)
        create(:pet, shelter: other_shelter, name: "Rex", species: "dog")

        result = described_class.call(shelter: shelter, user: user, rows: [ row(valid_row) ])

        expect(result.data[:imported].length).to eq(1)
        expect(result.data[:duplicates]).to be_empty
      end

      it "falls back to name + species when birth_date is blank" do
        create(:pet, shelter: shelter, name: "Rex", species: "dog")

        result = described_class.call(shelter: shelter, user: user, rows: [ row(valid_row) ])

        expect(shelter.pets.undiscarded.count).to eq(1)
        expect(result.data[:duplicates].length).to eq(1)
      end
    end

    context "status column" do
      it "defaults to available" do
        described_class.call(shelter: shelter, user: user, rows: [ row(valid_row) ])
        expect(shelter.pets.last.status).to eq("available")
      end

      it "accepts an explicit status and rejects 'removed'" do
        described_class.call(shelter: shelter, user: user, rows: [ row(valid_row("status" => "on_hold")) ])
        expect(shelter.pets.last.status).to eq("on_hold")

        result = described_class.call(
          shelter: shelter, user: user, rows: [ row(valid_row("status" => "removed")) ]
        )
        expect(shelter.pets.undiscarded.count).to eq(1)
        expect(result.data[:errors].length).to eq(1)
      end
    end
  end
end

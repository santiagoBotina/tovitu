require "rails_helper"

RSpec.describe PetImport do
  describe "associations" do
    it { is_expected.to belong_to(:shelter) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending processing completed failed]) }
    it { is_expected.to validate_presence_of(:file_name) }
  end

  describe "status predicates" do
    it "treats pending and processing as pending" do
      expect(build(:pet_import, status: "pending")).to be_pending
      expect(build(:pet_import, status: "processing")).to be_pending
      expect(build(:pet_import, status: "processing")).not_to be_completed
    end

    it "marks completed and failed states" do
      expect(build(:pet_import, :completed)).to be_completed
      expect(build(:pet_import, :failed)).to be_failed
    end
  end

  describe "summary accessors" do
    let(:import) do
      build(:pet_import, summary: {
        "imported" => [ { "row" => 2, "name" => "Rex", "id" => 1 } ],
        "duplicates" => [ { "row" => 3, "name" => "Rex" } ],
        "errors" => [ { "row" => 4, "name" => "Luna", "fields" => { "species" => [ "invalid" ] } } ]
      })
    end

    it "exposes imported, duplicate, and error rows" do
      expect(import.imported_rows).to eq([ { "row" => 2, "name" => "Rex", "id" => 1 } ])
      expect(import.duplicate_rows).to eq([ { "row" => 3, "name" => "Rex" } ])
      expect(import.error_rows).to eq([ { "row" => 4, "name" => "Luna", "fields" => { "species" => [ "invalid" ] } } ])
    end

    it "defaults to empty arrays" do
      expect(build(:pet_import).imported_rows).to eq([])
      expect(build(:pet_import).duplicate_rows).to eq([])
      expect(build(:pet_import).error_rows).to eq([])
    end
  end
end

require "rails_helper"
require "csv"

RSpec.describe Pets::ImportParser do
  def write_csv(content, filename: "pets.csv")
    file = Tempfile.new([ "pets", ".csv" ])
    file.write(content)
    file.flush
    { path: file.path, filename: filename }
  end

  describe "#call" do
    it "parses a valid CSV into canonical rows" do
      source = write_csv("name,species,age_category,sex,birth_date,size\nRex,dog,young,male,2024-03-01,medium\n")

      result = described_class.call(path: source[:path], filename: source[:filename])

      expect(result).to be_success
      expect(result.data[:headers]).to include("name", "species")
      expect(result.data[:rows]).to eq([
        { row_number: 2, values: { "name" => "Rex", "species" => "dog", "age_category" => "young", "sex" => "male", "birth_date" => "2024-03-01", "size" => "medium" } }
      ])
    end

    it "normalizes en and es headers to canonical columns" do
      source = write_csv("Nombre,Especie,Edad,Sexo\nRex,Perro,joven,Macho\n")

      result = described_class.call(path: source[:path], filename: source[:filename])

      expect(result).to be_success
      expect(result.data[:rows].first[:values]).to eq(
        "name" => "Rex", "species" => "Perro", "age_category" => "joven", "sex" => "Macho"
      )
    end

    it "detects semicolon-delimited CSV files" do
      source = write_csv("name;species;age_category;sex\nRex;dog;young;male\n")

      result = described_class.call(path: source[:path], filename: source[:filename])

      expect(result).to be_success
      expect(result.data[:rows].first[:values]["name"]).to eq("Rex")
    end

    it "strips a UTF-8 BOM from the first header" do
      source = write_csv("\xEF\xBB\xBFname,species,age_category,sex\nRex,dog,young,male\n")

      result = described_class.call(path: source[:path], filename: source[:filename])

      expect(result).to be_success
      expect(result.data[:headers].first).to eq("name")
    end

    it "parses an xlsx file" do
      path = Rails.root.join("spec/fixtures/files/pets.xlsx").to_s

      result = described_class.call(path: path, filename: "pets.xlsx")

      expect(result).to be_success
      expect(result.data[:rows].first[:values]).to include(
        "name" => "Rex", "species" => "dog", "age_category" => "young", "sex" => "male"
      )
    end

    it "rejects unsupported file formats" do
      source = write_csv("name,species\nRex,dog\n", filename: "pets.txt")

      result = described_class.call(path: source[:path], filename: source[:filename])

      expect(result).to be_failure
      expect(result.errors.first).to match(/CSV or Excel/)
    end

    it "fails with the missing required column names" do
      source = write_csv("name,species,sex\nRex,dog,male\n")

      result = described_class.call(path: source[:path], filename: source[:filename])

      expect(result).to be_failure
      expect(result.errors.first).to include("Age")
    end

    it "fails on an empty file" do
      source = write_csv("\n")

      result = described_class.call(path: source[:path], filename: source[:filename])

      expect(result).to be_failure
      expect(result.errors.first).to match(/empty/)
    end
  end
end

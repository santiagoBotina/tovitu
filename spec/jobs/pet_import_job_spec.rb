require "rails_helper"

RSpec.describe PetImportJob do
  include ActiveJob::TestHelper

  let(:shelter) { create(:shelter) }
  let(:user) { create(:user, :shelter_admin, shelter: shelter) }

  def attach_csv(import, content)
    import.file.attach(io: StringIO.new(content), filename: import.file_name, content_type: "text/csv")
  end

  it "imports valid rows and marks the import completed with a persisted summary" do
    import = create(:pet_import, shelter: shelter, user: user, file_name: "pets.csv")
    attach_csv(import, "name,species,age_category,sex\nRex,dog,young,male\nLuna,cat,baby,female\n")

    expect { described_class.perform_now(import.id) }.to change(Pet, :count).by(2)

    import.reload
    expect(import).to be_completed
    expect(import.imported_count).to eq(2)
    expect(import.total_count).to eq(2)
    expect(import.error_count).to eq(0)
    expect(import.summary["imported"]).to include(a_hash_including("name" => "Rex"))
    expect(import.completed_at).to be_present
  end

  it "reports row-level errors and still imports valid rows" do
    import = create(:pet_import, shelter: shelter, user: user, file_name: "pets.csv")
    attach_csv(import, "name,species,age_category,sex\nRex,dog,young,male\nBad,dragon,young,male\n")

    described_class.perform_now(import.id)

    import.reload
    expect(import).to be_completed
    expect(import.imported_count).to eq(1)
    expect(import.error_count).to eq(1)
    expect(import.summary["errors"].first["fields"].keys).to include("species")
  end

  it "marks the import failed with a friendly message when required columns are missing" do
    import = create(:pet_import, shelter: shelter, user: user, file_name: "pets.csv")
    attach_csv(import, "name,species\nRex,dog\n")

    expect { described_class.perform_now(import.id) }.not_to change(Pet, :count)

    import.reload
    expect(import).to be_failed
    expect(import.error).to match(/column/i)
  end

  it "marks the import failed on an unreadable file" do
    import = create(:pet_import, shelter: shelter, user: user, file_name: "pets.csv")
    attach_csv(import, "name,species,age_category,sex\nRex,dog,young,male\n")

    allow(Pets::ImportProcessor).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now(import.id) }.not_to raise_error

    expect(import.reload).to be_failed
    expect(import.error).to eq("boom")
  end

  it "is a no-op when the import is not pending" do
    import = create(:pet_import, :completed, shelter: shelter, user: user, file_name: "pets.csv")

    expect { described_class.perform_now(import.id) }.not_to change(Pet, :count)
    expect(import.reload).to be_completed
  end

  it "is a no-op when the import record no longer exists" do
    expect { described_class.perform_now(123_456) }.not_to raise_error
  end
end

require "rails_helper"

RSpec.describe "Shelter::PetImports" do
  include ActiveJob::TestHelper

  let(:shelter) { create(:shelter) }
  let(:user) { create(:user, :verified, :shelter_admin, shelter: shelter) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  let(:valid_csv) do
    Rack::Test::UploadedFile.new(
      StringIO.new("name,species,age_category,sex\nRex,dog,young,male\nLuna,cat,baby,female\n"),
      "text/csv",
      original_filename: "pets.csv"
    )
  end

  let(:xlsx_file) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/pets.xlsx"), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", original_filename: "pets.xlsx") }

  describe "POST /shelter/pet_imports" do
    it "creates a pending import, attaches the file, and enqueues the job" do
      expect {
        post shelter_pet_imports_path, params: { pet_import: { file: valid_csv } }
      }.to change(PetImport, :count).by(1)
       .and have_enqueued_job(PetImportJob)

      import = PetImport.last
      expect(import.status).to eq("pending")
      expect(import.file_name).to eq("pets.csv")
      expect(import.file).to be_attached
      expect(response).to redirect_to(shelter_pet_import_path(import))
    end

    it "accepts xlsx files" do
      expect {
        post shelter_pet_imports_path, params: { pet_import: { file: xlsx_file } }
      }.to change(PetImport, :count).by(1)
    end

    it "rejects missing files with a friendly error" do
      expect {
        post shelter_pet_imports_path, params: { pet_import: { file: nil } }
      }.not_to change(PetImport, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("shelter.pet_imports.errors.file_required"))
    end

    it "rejects unsupported extensions" do
      file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "pets.txt")

      expect {
        post shelter_pet_imports_path, params: { pet_import: { file: file } }
      }.not_to change(PetImport, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("CSV or Excel")
    end

    it "runs the background import end to end" do
      post shelter_pet_imports_path, params: { pet_import: { file: valid_csv } }

      perform_enqueued_jobs(only: PetImportJob)

      import = PetImport.last
      expect(import.reload).to be_completed
      expect(shelter.pets.undiscarded.count).to eq(2)
      expect(import.imported_count).to eq(2)
    end

    it "blocks users without a shelter" do
      individual = create(:user, :verified)
      delete session_path
      post session_path, params: { session: { email: individual.email, password: "password123" } }

      post shelter_pet_imports_path, params: { pet_import: { file: valid_csv } }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /shelter/pet_imports/:id" do
    it "renders the persisted summary for a completed import" do
      import = create(:pet_import, :completed, shelter: shelter, user: user, file_name: "pets.csv")

      get shelter_pet_import_path(import)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("shelter.pet_imports.summary.title"))
      expect(response.body).to include("Rex")
    end

    it "renders progress for a pending import" do
      import = create(:pet_import, shelter: shelter, user: user, file_name: "pets.csv")

      get shelter_pet_import_path(import)

      expect(response.body).to include(I18n.t("shelter.pet_imports.progress.importing_title"))
    end

    it "404s imports belonging to another shelter" do
      other_shelter = create(:shelter)
      import = create(:pet_import, shelter: other_shelter, user: user, file_name: "pets.csv")

      get shelter_pet_import_path(import)

      expect(response).to redirect_to(shelter_pet_imports_path)
    end
  end

  describe "GET /shelter/pet_imports/:id/status" do
    it "returns a turbo_stream that swaps the summary once complete" do
      import = create(:pet_import, :completed, shelter: shelter, user: user, file_name: "pets.csv")

      get status_shelter_pet_import_path(import), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("pet-import-summary")
    end

    it "returns a JSON status payload" do
      import = create(:pet_import, shelter: shelter, user: user, file_name: "pets.csv")

      get status_shelter_pet_import_path(import), as: :json

      expect(response.parsed_body["status"]).to eq("pending")
      expect(response.parsed_body["total_count"]).to eq(0)
    end
  end

  describe "GET /shelter/pet_imports/template" do
    it "downloads a CSV template" do
      get template_shelter_pet_imports_path

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")
      expect(response.body).to include("name,species")
    end
  end

  describe "GET /shelter/pet_imports" do
    it "lists the shelter's imports" do
      import = create(:pet_import, :completed, shelter: shelter, user: user, file_name: "pets.csv")

      get shelter_pet_imports_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(import.file_name)
    end
  end
end

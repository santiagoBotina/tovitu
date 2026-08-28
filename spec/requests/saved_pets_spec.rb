require "rails_helper"

RSpec.describe "Saved pets" do
  include ActiveJob::TestHelper

  describe "GET /saved_pets" do
    it "renders server-backed saved pets for a signed-in individual" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)

      get saved_pets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(pet.name)
      expect(response.body).to include(%(id="save-button-#{pet.id}"))
    end

    it "renders the empty state for a signed-out visitor without saved pets" do
      get saved_pets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("saved_pets.index.empty_title"))
    end

    it "shows the importing notice while a background import is pending" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      create(:favorites_import, user: user, status: "pending", requested_ids: [ 1 ])

      get saved_pets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("saved_pets.import.importing_title"))
      expect(response.body).to include('data-favorites-import-status="pending"')
    end

    it "shows a retryable notice when the import failed" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      create(:favorites_import, user: user, status: "failed", requested_ids: [ 1 ])

      get saved_pets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(I18n.t("saved_pets.import.failed_title")))
      expect(response.body).to include(I18n.t("saved_pets.import.retry"))
    end
  end

  describe "POST /saved_pets/import" do
    it "creates a pending import and enqueues the background job" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet1 = create(:pet)
      pet2 = create(:pet, status: "on_hold")

      expect do
        post import_saved_pets_path,
             params: { pet_ids: "#{pet1.id},#{pet2.id}" },
             headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      end.to change(FavoritesImport, :count).by(1)
       .and have_enqueued_job(FavoritesImportJob)

      import = user.favorites_imports.last
      expect(import.status).to eq("pending")
      expect(import.requested_ids).to contain_exactly(pet1.id, pet2.id)
      expect(import.total_count).to eq(2)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "imports available pets when the job runs" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet1 = create(:pet)
      pet2 = create(:pet, status: "on_hold")

      post import_saved_pets_path, params: { pet_ids: "#{pet1.id},#{pet2.id}" }
      perform_enqueued_jobs(only: FavoritesImportJob)

      expect(user.saved_pets.pluck(:pet_id)).to include(pet1.id)
      expect(user.saved_pets.pluck(:pet_id)).not_to include(pet2.id)
      import = user.favorites_imports.last
      expect(import.status).to eq("completed")
      expect(import.imported_count).to eq(1)
    end

    it "is idempotent — pre-existing favorites are preserved" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)

      post import_saved_pets_path, params: { pet_ids: pet.id.to_s }
      perform_enqueued_jobs(only: FavoritesImportJob)

      expect(user.saved_pets.count).to eq(1)
    end

    it "accepts array-style pet_ids params" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet1 = create(:pet)
      pet2 = create(:pet)

      post import_saved_pets_path, params: { pet_ids: [ pet1.id.to_s, pet2.id.to_s ] }
      perform_enqueued_jobs(only: FavoritesImportJob)

      expect(user.saved_pets.pluck(:pet_id)).to contain_exactly(pet1.id, pet2.id)
    end

    it "silently ignores non-numeric pet_ids" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      expect do
        post import_saved_pets_path, params: { pet_ids: "abc,1e5,;DROP TABLE pets;--" }
        perform_enqueued_jobs(only: FavoritesImportJob)
      end.not_to change(SavedPet, :count)
    end

    it "redirects unauthenticated visitors to the login page" do
      post import_saved_pets_path

      expect(response).to redirect_to(new_session_path)
    end

    it "returns the pending status as JSON" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet = create(:pet)

      post import_saved_pets_path,
           params: { pet_ids: pet.id.to_s },
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("status" => "pending", "total_count" => 1)
    end

    it "reuses a pending import instead of stacking duplicate records" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet = create(:pet)
      existing = create(:favorites_import, user: user, status: "pending", requested_ids: [ pet.id ])

      expect do
        post import_saved_pets_path, params: { pet_ids: pet.id.to_s }
      end.not_to change(FavoritesImport, :count)

      expect(enqueued_jobs).to be_empty
      expect(existing.reload.status).to eq("pending")
    end

    it "reuses a failed import, resetting it to pending and re-enqueuing" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet = create(:pet)
      existing = create(:favorites_import, user: user, status: "failed", requested_ids: [ 1 ])

      expect do
        post import_saved_pets_path, params: { pet_ids: pet.id.to_s }
      end.to have_enqueued_job(FavoritesImportJob)

      expect(existing.reload.status).to eq("pending")
      expect(existing.requested_ids).to eq([ pet.id ])
      expect(existing.total_count).to eq(1)
    end

    it "rejects non-individual accounts" do
      shelter_admin = create(:user, :verified, :onboarding_completed, :shelter_admin)
      shelter = create(:shelter)
      shelter_admin.update!(shelter: shelter)
      post session_path, params: { session: { email: shelter_admin.email, password: "password123" } }

      pet = create(:pet)
      post import_saved_pets_path, params: { pet_ids: pet.id.to_s }

      expect(response).to redirect_to(saved_pets_path)
      expect(shelter_admin.saved_pets).to be_empty
    end
  end

  describe "GET /saved_pets/import_status" do
    it "returns the pending status as JSON" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      create(:favorites_import, user: user, status: "pending", requested_ids: [ 1 ])

      get import_status_saved_pets_path, headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("status" => "pending")
    end

    it "returns the completed status and refreshes the list via turbo_stream" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)
      create(:favorites_import, user: user, status: "completed", requested_ids: [ pet.id ], imported_count: 1)

      get import_status_saved_pets_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("saved-pets-grid")
      expect(response.body).to include(pet.name)
    end

    it "communicates a partial import as N of M in the summary toast" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)
      create(:favorites_import, user: user, status: "completed", requested_ids: [ pet.id, 999_999 ], imported_count: 1, total_count: 2)

      get import_status_saved_pets_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include(I18n.t("saved_pets.import.imported_partial_one", total: 2))
    end

    it "uses the plain summary when every requested pet was imported" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)
      create(:favorites_import, user: user, status: "completed", requested_ids: [ pet.id ], imported_count: 1, total_count: 1)

      get import_status_saved_pets_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include(I18n.t("saved_pets.import.imported_one"))
      expect(response.body).not_to include("of 1 favorites")
    end
  end

  describe "POST /saved_pets/retry_import" do
    it "re-enqueues a failed import" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      import = create(:favorites_import, user: user, status: "failed", requested_ids: [ 1 ])

      expect do
        post retry_import_saved_pets_path, params: { favorites_import_id: import.id }
      end.to have_enqueued_job(FavoritesImportJob)

      expect(import.reload.status).to eq("pending")
    end
  end
end
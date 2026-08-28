require "rails_helper"

RSpec.describe "QA edge checks" do
  include ActiveJob::TestHelper

  it "import redirects to saved pets for HTML format" do
    user = create(:user, :verified, :onboarding_completed)
    post session_path, params: { session: { email: user.email, password: "password123" } }
    pet = create(:pet)

    post import_saved_pets_path, params: { pet_ids: pet.id.to_s }

    expect(response).to redirect_to(saved_pets_path)
  end

  it "import_status returns none for signed-out users" do
    get import_status_saved_pets_path, headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq("status" => "none")
  end

  it "retry_import redirects unauthenticated visitors" do
    post retry_import_saved_pets_path, params: { favorites_import_id: 1 }

    expect(response).to redirect_to(new_session_path)
  end

  it "retry_import is a no-op for a completed import" do
    user = create(:user, :verified, :onboarding_completed)
    post session_path, params: { session: { email: user.email, password: "password123" } }
    import = create(:favorites_import, user: user, status: "completed", requested_ids: [ 1 ])

    expect do
      post retry_import_saved_pets_path, params: { favorites_import_id: import.id }
    end.not_to have_enqueued_job(FavoritesImportJob)

    expect(import.reload.status).to eq("completed")
  end

  it "import_status turbo_stream shows failed notice for a failed import" do
    user = create(:user, :verified, :onboarding_completed)
    post session_path, params: { session: { email: user.email, password: "password123" } }
    create(:favorites_import, user: user, status: "failed", requested_ids: [ 1 ])

    get import_status_saved_pets_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.body).to include('data-favorites-import-status="failed"')
    expect(response.body).to include(I18n.t("saved_pets.import.retry"))
  end
end

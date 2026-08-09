require "rails_helper"

RSpec.describe "AdoptionRequests" do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }

  before do
    post session_path, params: { session: { email: adopter.email, password: "password123" } }
  end

  describe "GET /adoption_requests" do
    let!(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter) }

    it "returns a successful response" do
      get adoption_requests_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the list when the pet has a photo" do
      pet.photos.attach(fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg"))
      get adoption_requests_path
      expect(response).to have_http_status(:ok)
    end

    it "displays the user's requests" do
      get adoption_requests_path
      expect(response.body).to include(pet.name)
    end

    it "does not display other users' requests" do
      other_request = create(:adoption_request)
      get adoption_requests_path
      expect(response.body).not_to include(other_request.pet.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to root" do
        get adoption_requests_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /adoption_requests/:id" do
    let(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter) }

    it "returns a successful response" do
      get adoption_request_path(request)
      expect(response).to have_http_status(:ok)
    end

    it "renders the request when the pet has a photo" do
      pet.photos.attach(fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg"))
      get adoption_request_path(request)
      expect(response).to have_http_status(:ok)
    end

    it "prevents access to other users' requests" do
      other_request = create(:adoption_request)
      get adoption_request_path(other_request)
      expect(response).to redirect_to(root_path)
    end

    it "links to the pet profile with a back_to param so the pet page can return here" do
      get adoption_request_path(request)
      expect(response.body).to include(
        %(href="#{pet_path(request.pet, back_to: adoption_request_path(request))}")
      )
    end
  end

  describe "GET /adoption_requests/new" do
    it "renders the new request form" do
      get new_adoption_request_path(pet_id: pet.id)
      expect(response).to have_http_status(:ok)
    end

    it "renders the form when the pet has a photo" do
      pet.photos.attach(fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg"))
      get new_adoption_request_path(pet_id: pet.id)
      expect(response).to have_http_status(:ok)
    end

    it "places the additional answer fields inside the request form so they are submitted" do
      get new_adoption_request_path(pet_id: pet.id)
      form_html = response.body.match(%r{<form.*</form>}m).to_s
      expect(form_html).to include('name="additional_answers[interest_reason]"')
      expect(form_html).to include('name="additional_answers[home_description]"')
      expect(form_html).to include('name="additional_answers[current_pets_details]"')
      expect(form_html).to include('name="additional_answers[something_else]"')
    end

    it "shows the one-line transparency note (zero new required fields)" do
      get new_adoption_request_path(pet_id: pet.id)
      expect(response.body).to include(I18n.t("adoption_requests.new.transparency_note"))
    end

    it "redirects for unavailable pets" do
      pet.update!(status: :adopted, adopted_at: Time.current)
      get new_adoption_request_path(pet_id: pet.id)
      expect(response).to redirect_to(pets_path)
    end

    context "when onboarding is incomplete" do
      let(:adopter) { create(:user, :verified) }

      it "redirects to onboarding" do
        get new_adoption_request_path(pet_id: pet.id)
        expect(response).to redirect_to("/en/onboarding/individual/questions")
      end
    end
  end

  describe "POST /adoption_requests" do
    it "creates a new adoption request" do
      expect {
        post adoption_requests_path, params: { pet_id: pet.id }
      }.to change(AdoptionRequest, :count).by(1)
    end

    it "enqueues the async adopter insight generation" do
      expect {
        post adoption_requests_path, params: { pet_id: pet.id }
      }.to have_enqueued_job(Ai::GenerateAdopterInsightJob).with(request_id: an_instance_of(Integer))
    end

    it "redirects to the request show page" do
      post adoption_requests_path, params: { pet_id: pet.id }
      expect(response).to redirect_to(adoption_request_path(AdoptionRequest.last))
    end

    it "flashes the first-application milestone on the first request" do
      post adoption_requests_path, params: { pet_id: pet.id }
      expect(flash[:notice]).to eq(I18n.t("gamification.milestone_unlocked.first_application"))
    end

    it "does not flash the first-application milestone on a second request" do
      create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter, status: :pending)
      other_pet = create(:pet, shelter: shelter)

      post adoption_requests_path, params: { pet_id: other_pet.id }

      expect(flash[:notice]).not_to eq(I18n.t("gamification.milestone_unlocked.first_application"))
    end

    it "with additional answers" do
      expect {
        post adoption_requests_path, params: {
          pet_id: pet.id,
          additional_answers: { interest_reason: "I love dogs!" }
        }
      }.to change(AdoptionRequest, :count).by(1)
      expect(AdoptionRequest.last.additional_answers).to include("interest_reason" => "I love dogs!")
    end

    context "when pet is not available" do
      before { pet.update!(status: :adopted, adopted_at: Time.current) }

      it "redirects with an alert" do
        post adoption_requests_path, params: { pet_id: pet.id }
        expect(response).to redirect_to(pet_path(pet))
      end
    end

    context "when duplicate request exists" do
      before { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter, status: :pending) }

      it "redirects with an alert" do
        post adoption_requests_path, params: { pet_id: pet.id }
        expect(response).to redirect_to(pet_path(pet))
      end
    end
  end

  describe "PATCH /adoption_requests/:id/withdraw" do
    let(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: shelter, status: :pending) }

    it "withdraws the request" do
      expect {
        patch withdraw_adoption_request_path(request)
      }.to change { request.reload.status }.from("pending").to("withdrawn")
    end

    it "redirects with a success notice" do
      patch withdraw_adoption_request_path(request)
      expect(response).to redirect_to(adoption_request_path(request))
    end

    it "prevents withdrawal by non-owner" do
      # Log out first, then log in as a different user
      delete session_path
      other_user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: other_user.email, password: "password123" } }
      patch withdraw_adoption_request_path(request)
      expect(request.reload.status).to eq("pending")
    end

    it "prevents withdrawal of non-withdrawable requests" do
      request.update!(status: :accepted)
      patch withdraw_adoption_request_path(request)
      expect(request.reload.status).to eq("accepted")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to root" do
        patch withdraw_adoption_request_path(request)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end

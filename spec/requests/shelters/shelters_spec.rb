require "rails_helper"

RSpec.describe "Shelters" do
  describe "GET /shelters" do
    it "returns a list of active shelters" do
      shelter = create(:shelter, :with_admin)
      get shelters_path
      expect(response).to have_http_status(:ok)
    end

    it "does not include discarded shelters" do
      active = create(:shelter, :with_admin, name: "Active Shelter")
      discarded = create(:shelter, :discarded, name: "Discarded Shelter")
      get shelters_path
      expect(response.body).to include(active.name)
      expect(response.body).not_to include(discarded.name)
    end

    it "does not include inactive shelters" do
      inactive = create(:shelter, :inactive, name: "Inactive Shelter")
      get shelters_path
      expect(response.body).not_to include(inactive.name)
    end

    it "filters by city" do
      shelter = create(:shelter, city: "Springfield", name: "Springfield Shelter")
      other = create(:shelter, city: "Portland", name: "Portland Shelter")
      get shelters_path, params: { city: "spring" }
      expect(response.body).to include(shelter.name)
      expect(response.body).not_to include(other.name)
    end

    it "filters by state" do
      shelter = create(:shelter, state: "OR", name: "OR Shelter")
      other = create(:shelter, state: "CA", name: "CA Shelter")
      get shelters_path, params: { state: "OR" }
      expect(response.body).to include(shelter.name)
      expect(response.body).not_to include(other.name)
    end

    it "filters by species" do
      shelter = create(:shelter, species_served: %w[dog cat], name: "Dog and Cat Shelter")
      other = create(:shelter, species_served: [ "cat" ], name: "Cats Only")
      get shelters_path, params: { species: "dog" }
      expect(response.body).to include(shelter.name)
      expect(response.body).not_to include(other.name)
    end
  end

  describe "GET /shelters/:id" do
    it "shows a shelter" do
      shelter = create(:shelter, :with_admin)
      get shelter_path(id: shelter)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for discarded shelters" do
      shelter = create(:shelter, :discarded)
      get shelter_path(id: shelter)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /shelters/new" do
    it "requires authentication" do
      get new_shelter_path
      expect(response).to redirect_to(root_path)
    end

    it "renders the form for verified users without a shelter" do
      user = create(:user, :verified, :staff, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get new_shelter_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects users who already have a shelter" do
      shelter = create(:shelter)
      user = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      get new_shelter_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /shelters" do
    it "creates a shelter and assigns admin role" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      expect do
        post shelters_path, params: {
          shelter: {
            name: "Happy Paws Rescue",
            street: "123 Main St",
            city: "Portland",
            state: "OR",
            zip: "97201",
            phone: "503-555-0123",
            species_served: %w[dog cat]
          }
        }
      end.to change(Shelter, :count).by(1)

      expect(response).to redirect_to(shelter_dashboard_path(shelter_id: Shelter.last))
      expect(user.reload.shelter).to eq(Shelter.last)
      expect(user.reload.role).to eq("shelter_admin")
    end

    it "rejects unverified users" do
      user = create(:user, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      post shelters_path, params: {
        shelter: { name: "Test", street: "123 St", city: "City", state: "OR", zip: "97201", phone: "503-555-0123" }
      }
      expect(response).to redirect_to(root_path)
    end

    it "rejects duplicate shelter names" do
      create(:shelter, name: "Happy Paws Rescue")
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      post shelters_path, params: {
        shelter: {
          name: "Happy Paws Rescue",
          street: "456 Oak Ave",
          city: "Portland",
          state: "OR",
          zip: "97202",
          phone: "503-555-0456",
          species_served: [ "dog" ]
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects when required fields are missing" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      post shelters_path, params: { shelter: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /shelters/:id/edit" do
    it "requires admin authorization" do
      shelter = create(:shelter, :with_admin)
      user = create(:user, :verified, shelter: shelter)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      get edit_shelter_path(id: shelter)
      expect(response).to redirect_to(root_path)
    end

    it "redirects shelter staff with a flash instead of a 500" do
      shelter = create(:shelter)
      staff = create(:user, :verified, :shelter_staff, :onboarding_completed, shelter: shelter)
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      get edit_shelter_path(id: shelter)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.unauthorized"))
    end

    it "allows shelter admin to edit" do
      shelter = create(:shelter)
      admin = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter)
      post session_path, params: { session: { email: admin.email, password: "password123" } }

      get edit_shelter_path(id: shelter)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /shelters/:id" do
    it "updates shelter profile" do
      shelter = create(:shelter)
      admin = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter)
      post session_path, params: { session: { email: admin.email, password: "password123" } }

      patch shelter_path(id: shelter), params: { shelter: { name: "Updated Name" } }
      expect(response).to redirect_to(shelter_path(id: shelter))
      expect(shelter.reload.name).to eq("Updated Name")
    end

    it "rejects non-admin updates" do
      shelter = create(:shelter, :with_staff)
      staff = shelter.users.first
      staff.update!(onboarding_completed_at: Time.current)
      post session_path, params: { session: { email: staff.email, password: "password123" } }

      patch shelter_path(id: shelter), params: { shelter: { name: "Hacked Name" } }
      expect(response).to redirect_to(root_path)
    end
  end
end

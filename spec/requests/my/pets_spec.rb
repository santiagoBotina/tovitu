require "rails_helper"

RSpec.describe "My Pets (publisher milestone)" do
  let(:user) { create(:user, :verified, :onboarding_completed) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  def valid_pet_params
    {
      pet: {
        name: "Buddy",
        species: "dog",
        breed: "Labrador",
        age_category: "young",
        sex: "male",
        status: "available",
        photos: [ fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg") ]
      }
    }
  end

  describe "POST /my/pets" do
    it "flashes the publisher milestone on the first published pet" do
      post my_pets_path, params: valid_pet_params

      expect(response).to redirect_to(my_pet_path(Pet.last))
      expect(flash[:notice]).to eq(I18n.t("gamification.milestone_unlocked.publisher"))
    end

    it "does not flash the publisher milestone on a second published pet" do
      create(:pet, :individual_listed, publisher: user)

      post my_pets_path, params: valid_pet_params

      expect(flash[:notice]).not_to eq(I18n.t("gamification.milestone_unlocked.publisher"))
    end
  end
end

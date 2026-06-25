require "rails_helper"

RSpec.describe SavedPet, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:pet) }
  end

  describe "validations" do
    subject { create(:saved_pet) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:pet_id) }
  end
end

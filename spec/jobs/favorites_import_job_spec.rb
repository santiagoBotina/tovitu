require "rails_helper"

RSpec.describe FavoritesImportJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "imports available pets and marks the import completed" do
      user = create(:user)
      pet1 = create(:pet)
      pet2 = create(:pet, status: "on_hold")
      import = create(:favorites_import, user: user, status: "pending", requested_ids: [ pet1.id, pet2.id ], total_count: 2)

      described_class.perform_now(import.id)

      expect(user.saved_pets.pluck(:pet_id)).to contain_exactly(pet1.id)
      expect(import.reload).to be_completed
      expect(import.imported_count).to eq(1)
      expect(import.completed_at).to be_present
    end

    it "preserves pre-existing favorites (idempotent)" do
      user = create(:user)
      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)
      import = create(:favorites_import, user: user, status: "pending", requested_ids: [ pet.id ])

      expect { described_class.perform_now(import.id) }.not_to change(SavedPet, :count)
      expect(import.reload).to be_completed
    end

    it "marks the import failed when something goes wrong" do
      user = create(:user)
      pet = create(:pet)
      import = create(:favorites_import, user: user, status: "pending", requested_ids: [ pet.id ])

      allow(Pet).to receive(:available).and_raise(StandardError, "boom")

      described_class.perform_now(import.id)

      expect(import.reload).to be_failed
      expect(import.error).to eq("boom")
    end

    it "is a no-op when the import is not pending" do
      user = create(:user)
      import = create(:favorites_import, user: user, status: "completed", requested_ids: [ 1 ])

      expect { described_class.perform_now(import.id) }.not_to change(SavedPet, :count)
      expect(import.reload).to be_completed
    end

    it "is a no-op when the import record no longer exists" do
      expect { described_class.perform_now(123_456) }.not_to raise_error
    end
  end
end
class AddPetFitToAdoptionRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :adoption_requests, :pet_fit_data, :jsonb, default: {}
    add_column :adoption_requests, :pet_fit_generated_at, :datetime
    add_column :adoption_requests, :pet_fit_version, :integer, default: 0, null: false
  end
end

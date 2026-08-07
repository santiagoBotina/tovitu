class AddPetFitSignalFingerprintToAdoptionRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :adoption_requests, :pet_fit_signal_fingerprint, :string
  end
end

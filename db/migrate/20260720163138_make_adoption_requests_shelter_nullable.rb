class MakeAdoptionRequestsShelterNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :adoption_requests, :shelter_id, true
  end
end

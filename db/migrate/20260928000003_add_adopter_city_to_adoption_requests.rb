class AddAdopterCityToAdoptionRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :adoption_requests, :adopter_city, :string
  end
end

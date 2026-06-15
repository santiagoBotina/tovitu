class AddShelterFkToUsers < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :users, :shelters
  end
end

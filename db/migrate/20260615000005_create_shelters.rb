class CreateShelters < ActiveRecord::Migration[8.1]
  def change
    create_table :shelters do |t|
      t.string :name, null: false
      t.string :street, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.string :phone, null: false
      t.string :website
      t.text :description
      t.jsonb :species_served, null: false, default: [ "dog" ]
      t.string :hours
      t.string :status, null: false, default: "active"
      t.datetime :discarded_at
      t.jsonb :adoption_policies, null: false, default: {}
      t.boolean :onboarding_completed, null: false, default: false

      t.timestamps
    end

    add_index :shelters, :name, unique: true
    add_index :shelters, :discarded_at
    add_index :shelters, :status
    add_index :shelters, :city
    add_index :shelters, :state
    add_index :shelters, :species_served, using: :gin
  end
end

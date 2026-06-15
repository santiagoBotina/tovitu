class CreatePets < ActiveRecord::Migration[8.1]
  def change
    create_table :pets do |t|
      t.references :shelter, null: false, foreign_key: true

      t.string :name, null: false
      t.string :species, null: false
      t.string :breed
      t.string :age_category, null: false
      t.date :birth_date
      t.string :size
      t.string :sex, null: false
      t.text :description
      t.jsonb :personality_traits, default: []
      t.text :medical_notes
      t.boolean :spayed_neutered, default: false
      t.boolean :vaccinated, default: false
      t.boolean :special_needs, default: false
      t.boolean :good_with_children
      t.boolean :good_with_dogs
      t.boolean :good_with_cats
      t.text :requirements
      t.string :status, null: false, default: "available"
      t.datetime :adopted_at
      t.datetime :discarded_at
      t.jsonb :photo_order, default: []

      t.timestamps
    end

    add_index :pets, :status
    add_index :pets, :species
    add_index :pets, :age_category
    add_index :pets, :size
    add_index :pets, :sex
    add_index :pets, :discarded_at
  end
end

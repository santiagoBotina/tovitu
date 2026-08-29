class CreatePetImports < ActiveRecord::Migration[8.1]
  def change
    create_table :pet_imports do |t|
      t.references :shelter, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :file_name, null: false
      t.integer :imported_count, null: false, default: 0
      t.integer :duplicate_count, null: false, default: 0
      t.integer :error_count, null: false, default: 0
      t.integer :total_count, null: false, default: 0
      t.text :error
      t.jsonb :summary, null: false, default: {}
      t.datetime :completed_at

      t.timestamps
    end

    add_index :pet_imports, [ :shelter_id, :created_at ]
  end
end

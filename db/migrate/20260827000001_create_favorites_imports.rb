class CreateFavoritesImports < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.jsonb :requested_ids, null: false, default: []
      t.integer :imported_count, null: false, default: 0
      t.integer :total_count, null: false, default: 0
      t.string :error
      t.datetime :completed_at

      t.timestamps
    end

    add_index :favorites_imports, [ :user_id, :created_at ]
  end
end
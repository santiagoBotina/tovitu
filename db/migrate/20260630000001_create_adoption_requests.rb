class CreateAdoptionRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :adoption_requests do |t|
      t.references :pet,     null: false, foreign_key: true
      t.references :adopter, null: false, foreign_key: { to_table: :users }
      t.references :shelter, null: false, foreign_key: true

      t.string :status, null: false, default: "pending"

      t.jsonb :decline_reasons

      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :adoption_requests, :status
    add_index :adoption_requests, [:adopter_id, :pet_id],
              unique: true,
              where: "status != 'declined'",
              name: "idx_adoption_requests_active_unique"

    create_table :adoption_request_timeline_events do |t|
      t.references :adoption_request, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    # t.references above already creates this index
  end
end

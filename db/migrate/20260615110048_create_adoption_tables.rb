class CreateAdoptionTables < ActiveRecord::Migration[8.1]
  def change
    create_table :adoption_applications do |t|
      t.references :pet,    null: false, foreign_key: true
      t.references :shelter, null: false, foreign_key: true

      t.string :status, null: false, default: "pending"

      t.string :applicant_name,  null: false
      t.string :applicant_email, null: false
      t.string :applicant_phone
      t.text   :applicant_address

      t.string :housing_type
      t.text   :current_pets
      t.text   :pet_experience
      t.jsonb  :questionnaire_answers, default: {}

      t.text   :notes
      t.string :rejection_reason
      t.string :token, null: false
      t.references :reviewed_by, foreign_key: { to_table: :users }

      t.datetime :completed_at
      t.datetime :withdrawn_at
      t.datetime :hold_expires_at

      t.datetime :discarded_at

      t.timestamps
    end

    add_index :adoption_applications, :token, unique: true
    add_index :adoption_applications, :status
    add_index :adoption_applications, :discarded_at
    add_index :adoption_applications, [ :shelter_id, :status ],
              name: "idx_applications_on_shelter_and_status"
    add_index :adoption_applications, [ :pet_id, :applicant_email ],
              unique: true,
              name: "idx_applications_on_pet_and_email"

    create_table :adoption_notes do |t|
      t.references :adoption_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.boolean :pinned, default: false
      t.timestamps
    end

    add_index :adoption_notes, [ :adoption_application_id, :pinned ],
              name: "idx_notes_on_application_and_pinned",
              where: "pinned = TRUE"

    create_table :adoption_timeline_events do |t|
      t.references :adoption_application, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :metadata, default: {}
      t.datetime :created_at, null: false
    end

    add_index :adoption_timeline_events, :event_type
    add_index :adoption_timeline_events, [ :adoption_application_id, :created_at ],
              name: "idx_timeline_on_application_and_date"
  end
end

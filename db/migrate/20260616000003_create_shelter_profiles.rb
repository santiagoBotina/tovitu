class CreateShelterProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :shelter_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :shelter, null: true, foreign_key: true

      t.string :organization_type
      t.string :pet_count_range
      t.string :adoption_involvement
      t.jsonb :approval_priorities, default: []
      t.jsonb :communication_channels, default: []
      t.jsonb :biggest_challenges, default: []
      t.string :approval_philosophy
      t.integer :onboarding_step, default: 0, null: false

      t.timestamps
    end
  end
end

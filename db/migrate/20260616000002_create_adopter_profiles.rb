class CreateAdopterProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :adopter_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.jsonb :weekend_activity, default: []
      t.string :activity_level
      t.string :ideal_companion
      t.string :pet_experience
      t.jsonb :adoption_goals, default: []
      t.string :daily_time_available
      t.string :personality
      t.string :adoption_priority
      t.integer :onboarding_step, default: 0, null: false

      t.timestamps
    end
  end
end

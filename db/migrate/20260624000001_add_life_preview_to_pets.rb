class AddLifePreviewToPets < ActiveRecord::Migration[8.1]
  def change
    add_column :pets, :life_preview_data, :jsonb
    add_column :pets, :life_preview_generated_at, :datetime
    add_column :pets, :life_preview_version, :integer, default: 0
    add_column :pets, :personality_spec, :text
    add_column :pets, :adopter_tips, :text

    add_column :shelters, :ai_features_enabled, :boolean, default: true
  end
end

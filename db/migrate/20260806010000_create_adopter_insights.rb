class CreateAdopterInsights < ActiveRecord::Migration[8.1]
  def change
    create_table :adopter_insights do |t|
      t.references :adopter, null: false, foreign_key: { to_table: :users }, index: { unique: true }

      t.jsonb :data, default: {}
      t.integer :version, default: 0, null: false
      t.string :signal_fingerprint
      t.datetime :generated_at

      t.timestamps
    end
  end
end

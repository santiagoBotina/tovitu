class AddLocationConsentToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :location_decision, :string
    add_column :users, :location_disclosure_version, :string
    add_column :users, :location_decision_at, :datetime

    execute <<~SQL.squish
      ALTER TABLE users
      ADD CONSTRAINT valid_location_decision
      CHECK (location_decision IS NULL OR location_decision IN ('shared', 'skipped'))
    SQL
  end

  def down
    execute "ALTER TABLE users DROP CONSTRAINT valid_location_decision"

    remove_column :users, :location_decision_at
    remove_column :users, :location_disclosure_version
    remove_column :users, :location_decision
  end
end

class CreateUserLocations < ActiveRecord::Migration[8.1]
  def up
    create_table :user_locations do |t|
      t.bigint :user_id, null: false
      t.string :city, null: false
      t.string :region
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :source, null: false, default: "manual"

      t.timestamps
    end

    add_foreign_key :user_locations, :users
    add_index :user_locations, :user_id, unique: true

    execute <<~SQL.squish
      ALTER TABLE user_locations
      ADD CONSTRAINT valid_location_source
      CHECK (source IN ('device', 'manual'))
    SQL
  end

  def down
    drop_table :user_locations
  end
end

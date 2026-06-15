class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :role, default: "staff", null: false
      t.datetime :verified_at
      t.bigint :shelter_id
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :shelter_id
    add_index :users, :discarded_at
  end
end

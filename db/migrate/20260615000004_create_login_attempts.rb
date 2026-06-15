class CreateLoginAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :login_attempts do |t|
      t.string :email, null: false
      t.string :ip_address, null: false
      t.string :user_agent
      t.datetime :attempted_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.boolean :success, null: false

      t.timestamps
    end

    add_index :login_attempts, :email
    add_index :login_attempts, [:email, :attempted_at]
  end
end

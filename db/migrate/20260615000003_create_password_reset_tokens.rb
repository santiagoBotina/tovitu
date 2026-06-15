class CreatePasswordResetTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :password_reset_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :consumed_at

      t.timestamps
    end

    add_index :password_reset_tokens, :token
  end
end

class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :in_app, default: true, null: false
      t.boolean :email, default: true, null: false
      t.boolean :whatsapp, default: false, null: false
      t.string :whatsapp_phone
      t.datetime :whatsapp_verified_at
      t.jsonb :per_kind_overrides, default: {}

      t.timestamps
    end

    add_index :notification_preferences, :user_id, unique: true, name: "idx_notification_preferences_user"
  end
end

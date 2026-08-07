class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body
      t.jsonb :metadata, default: {}
      t.datetime :read_at
      t.datetime :actionable_until
      t.string :action_url

      t.timestamps
    end

    add_index :notifications, [ :recipient_id, :read_at, :created_at ], name: "idx_notifications_unread"
    add_index :notifications, [ :notifiable_type, :notifiable_id ]
  end
end

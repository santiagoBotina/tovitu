class AddEmailDeliveryTrackingToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :email_delivered_at, :datetime
    add_column :notifications, :email_failed_at, :datetime
    add_column :notifications, :email_error, :text
  end
end

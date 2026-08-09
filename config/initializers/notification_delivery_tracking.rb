# Records the real outcome of routed notification emails onto the Notification
# record (delivered / failed + error). Mailers carry the notification id in an
# X-Tovitu-Notification-Id header (see Notifications::DeliveryTracker).
#
# Subscribed in `after_initialize` so the autoloader can resolve the constant.
Rails.application.config.after_initialize do
  Notifications::DeliveryTracker.subscribe!
end

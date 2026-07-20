class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  enum :kind, {
    request_submitted: "request_submitted",
    request_in_validation: "request_in_validation",
    request_accepted: "request_accepted",
    request_declined: "request_declined",
    request_withdrawn: "request_withdrawn",
    info_requested: "info_requested",
    info_received: "info_received",
    message_received: "message_received",
    pet_status_changed: "pet_status_changed",
    welcome: "welcome"
  }, validate: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  delegate :name, to: :actor, prefix: true, allow_nil: true

  def mark_as_read!
    update!(read_at: Time.current) unless read_at?
  end

  def read?
    read_at.present?
  end
end

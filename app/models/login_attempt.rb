class LoginAttempt < ApplicationRecord
  validates :email, presence: true
  validates :ip_address, presence: true

  scope :recent, -> { where(attempted_at: 15.minutes.ago..) }
  scope :failed, -> { where(success: false) }
  scope :by_email, ->(email) { where(email: email) }

  def self.recent_failures_for(email)
    by_email(email).recent.failed
  end

  def self.locked_out?(email)
    recent_failures_for(email).count >= 5
  end

  def self.lockout_ends_at(email)
    if locked_out?(email)
      recent_failures_for(email).maximum(:attempted_at) + 15.minutes
    end
  end

  def self.lockout_remaining_seconds(email)
    if (ends_at = lockout_ends_at(email))
      [ (ends_at - Time.current).ceil, 0 ].max
    else
      0
    end
  end
end

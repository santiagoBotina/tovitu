class PasswordResetToken < ApplicationRecord
  belongs_to :user

  has_secure_token :token

  validates :expires_at, presence: true

  scope :unexpired, -> { where("expires_at > ?", Time.current) }
  scope :unconsumed, -> { where(consumed_at: nil) }

  def expired?
    expires_at <= Time.current
  end

  def consumed?
    consumed_at.present?
  end

  def consume!
    update!(consumed_at: Time.current)
  end

  def self.valid_token(token_string)
    find_by(token: token_string, consumed_at: nil)
  end
end

class Invitation < ApplicationRecord
  TOKEN_LENGTH = 32

  belongs_to :shelter
  belongs_to :created_by, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(TOKEN_LENGTH)
  end

  def set_expiry
    self.expires_at ||= 7.days.from_now
  end
end

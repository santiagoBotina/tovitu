class Invitation < ApplicationRecord
  TOKEN_LENGTH = 32
  # Roles that can be assigned by invitation. The owner role is deliberately
  # excluded: a shelter has exactly one owner and it cannot be invited
  # (BR-46-3). Enforced at the DB level by valid_invitation_role.
  ROLES = %w[administrator staff_member].freeze

  belongs_to :shelter
  belongs_to :created_by, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  scope :pending, -> { where(accepted_at: nil, cancelled_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil, cancelled_at: nil).where("expires_at <= ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :cancelled, -> { where.not(cancelled_at: nil) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def cancelled?
    cancelled_at.present?
  end

  # Lifecycle guards (defense-in-depth): the services validate state before
  # calling these, but a cancelled/expired/accepted invitation must never be
  # transitioned directly.
  def accept!
    raise ActiveRecord::RecordInvalid, self unless pending?

    update!(accepted_at: Time.current)
  end

  def cancel!
    raise ActiveRecord::RecordInvalid, self unless pending?

    update!(cancelled_at: Time.current)
  end

  private

  def pending?
    !accepted? && !cancelled? && !expired?
  end

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(TOKEN_LENGTH)
  end

  def set_expiry
    self.expires_at ||= 7.days.from_now
  end
end

class User < ApplicationRecord
  ROLES = %w[admin staff].freeze

  has_secure_password

  belongs_to :shelter, optional: true

  has_many :email_verification_tokens, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :role, inclusion: { in: ROLES }

  before_validation :normalize_email

  scope :verified, -> { where.not(verified_at: nil) }
  scope :unverified, -> { where(verified_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }
  scope :undiscarded, -> { where(discarded_at: nil) }
  scope :admin, -> { where(role: "admin") }
  scope :staff, -> { where(role: "staff") }

  def verified?
    verified_at.present?
  end

  def staff?
    role == "staff"
  end

  def admin?
    role == "admin"
  end

  def shelter_admin?
    admin? && shelter_id.present?
  end

  def discard
    update!(discarded_at: Time.current)
  end

  def undiscard
    update!(discarded_at: nil)
  end

  def discarded?
    discarded_at.present?
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def password_required?
    new_record? || password.present?
  end
end

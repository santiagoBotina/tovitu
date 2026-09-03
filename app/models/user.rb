class User < ApplicationRecord
  ROLES = %w[individual shelter_admin shelter_staff admin staff].freeze
  SHELTER_ROLES = %w[owner administrator staff_member].freeze

  has_secure_password

  belongs_to :shelter, optional: true

  has_many :email_verification_tokens, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy

  has_many :saved_pets, dependent: :destroy
  has_many :favorites_imports, dependent: :destroy

  has_many :published_pets, class_name: "Pet", foreign_key: :publisher_id, dependent: :destroy
  has_many :adoption_requests, foreign_key: :adopter_id, dependent: :destroy
  has_many :reviewed_adoption_requests, class_name: "AdoptionRequest", foreign_key: :reviewed_by_id, dependent: :nullify

  has_one :individual_profile, dependent: :destroy
  has_one :adopter_profile, dependent: :destroy
  has_one :shelter_profile, dependent: :destroy
  has_one :adopter_insight, foreign_key: :adopter_id, dependent: :destroy

  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_one :notification_preference, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :role, inclusion: { in: ROLES }
  validates :shelter_role, inclusion: { in: SHELTER_ROLES }, allow_nil: true

  before_validation :normalize_email
  before_validation :derive_shelter_role, if: -> { shelter_id.present? }

  scope :verified, -> { where.not(verified_at: nil) }
  scope :unverified, -> { where(verified_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }
  scope :undiscarded, -> { where(discarded_at: nil) }
  scope :individual, -> { where(role: "individual") }
  scope :shelter_admin, -> { where(role: "shelter_admin") }
  scope :shelter_staff, -> { where(role: "shelter_staff") }
  scope :admin, -> { where(role: "admin") }
  scope :staff, -> { where(role: "staff") }
  scope :shelter_owners, -> { where(shelter_role: "owner") }
  scope :shelter_administrators, -> { where(shelter_role: "administrator") }
  scope :shelter_staff_members, -> { where(shelter_role: "staff_member") }
  scope :shelter_members, -> { where.not(shelter_role: nil) }

  def verified?
    verified_at.present?
  end

  def individual?
    role == "individual"
  end
  alias_method :adopter?, :individual?

  def shelter_owner?
    shelter_role == "owner"
  end

  def shelter_administrator?
    shelter_role == "administrator"
  end

  def shelter_staff_member?
    shelter_role == "staff_member"
  end

  def shelter_member?
    shelter_role.present?
  end

  def shelter_user?
    shelter_member? || shelter_account_type? || admin? || staff?
  end

  def shelter_account_type?
    role.in?(%w[shelter_admin shelter_staff])
  end

  # Legacy predicates from the retired binary model. "shelter_admin" maps to
  # the owner role; "shelter_staff" maps to the staff_member role. Kept for
  # back-compat (AC-46-14); new code should use the shelter_role predicates.
  def shelter_admin?
    shelter_owner?
  end

  def shelter_staff?
    shelter_staff_member?
  end

  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def staff?
    role == "staff"
  end

  def admin?
    role == "admin"
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

  def derive_shelter_role
    return if shelter_role.present?

    self.shelter_role = case role
    when "shelter_admin" then "owner"
    when "shelter_staff" then "staff_member"
    end
  end

  def password_required?
    new_record? || password.present?
  end
end

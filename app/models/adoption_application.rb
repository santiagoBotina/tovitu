class AdoptionApplication < ApplicationRecord
  belongs_to :pet, touch: true
  belongs_to :shelter, touch: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  has_many :adoption_notes, dependent: :destroy
  has_many :adoption_timeline_events, dependent: :destroy

  STATUSES = %w[
    pending under_review approved rejected
    awaiting_response completed withdrawn cancelled expired
  ].freeze

  HOUSING_TYPES = %w[house apartment condo other].freeze

  enum :status, STATUSES.index_by(&:itself).transform_values(&:to_sym),
       prefix: true, default: "pending"

  validates :applicant_name,  presence: true
  validates :applicant_email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP,
                      message: I18n.t("adoptions.errors.invalid_email_format") }
  validates :token, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :housing_type, inclusion: { in: HOUSING_TYPES, allow_blank: true }
  validates :rejection_reason, presence: true, if: :status_rejected?

  before_validation :normalize_email, if: :applicant_email_changed?

  scope :pending,           -> { where(status: "pending") }
  scope :under_review,      -> { where(status: "under_review") }
  scope :approved,          -> { where(status: "approved") }
  scope :rejected,          -> { where(status: "rejected") }
  scope :awaiting_response, -> { where(status: "awaiting_response") }
  scope :completed,         -> { where(status: "completed") }
  scope :withdrawn,         -> { where(status: "withdrawn") }
  scope :cancelled,         -> { where(status: "cancelled") }
  scope :expired,           -> { where(status: "expired") }

  scope :active,    -> { where(status: %w[pending under_review awaiting_response]) }
  scope :closed,    -> { where(status: %w[approved rejected completed withdrawn cancelled expired]) }
  scope :by_shelter, ->(id) { where(shelter_id: id) }
  scope :by_pet,    ->(id) { where(pet_id: id) }
  scope :by_email,  ->(email) { where(applicant_email: email.to_s.downcase.strip) }
  scope :newest_first, -> { order(created_at: :desc) }

  scope :on_hold_expired, -> { approved.where(hold_expires_at: ...Time.current) }

  scope :undiscarded, -> { where(discarded_at: nil) }
  scope :discarded,   -> { where.not(discarded_at: nil) }

  def discard!
    update!(discarded_at: Time.current)
  end

  def undiscard!
    update!(discarded_at: nil)
  end

  def discarded?
    discarded_at.present?
  end

  def reference_number
    Adoptions::TokenGenerator.reference(token)
  end

  private

  def normalize_email
    self.applicant_email = applicant_email.to_s.downcase.strip
  end
end

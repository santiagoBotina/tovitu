class Shelter < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, dependent: :destroy
  has_many :pets, dependent: :restrict_with_error
  has_many :adoption_applications, dependent: :restrict_with_error
  has_many :adoption_requests, dependent: :restrict_with_error
  has_many :ai_documents, class_name: "Ai::Document", dependent: :destroy

  has_one_attached :logo
  has_one_attached :cover_image
  has_one_attached :profile_picture

  accepts_nested_attributes_for :users

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :street, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip, presence: true
  validates :phone, presence: true
  validates :species_served, presence: true
  validates :status, inclusion: { in: %w[active inactive] }

  validate :species_served_must_be_array
  validate :logo_validation, if: -> { logo.attached? }
  validate :cover_image_validation, if: -> { cover_image.attached? }
  validate :profile_picture_validation, if: -> { profile_picture.attached? }

  scope :with_ai_features, -> { where(ai_features_enabled: true) }
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :discarded, -> { where.not(discarded_at: nil) }
  scope :undiscarded, -> { where(discarded_at: nil) }

  def ai_features_enabled?
    return true if ai_features_enabled.nil?
    ai_features_enabled
  end

  def active?
    status == "active"
  end

  def discard!
    update!(discarded_at: Time.current)
  end

  def undiscard!
    update!(discarded_at: nil)
  end

  def discarded?
    discarded_at.present?
  end

  private

  def species_served_must_be_array
    return if species_served.is_a?(Array)

    errors.add(:species_served, "must be an array")
  end

  def logo_validation
    validate_image_attachment(:logo)
  end

  def cover_image_validation
    validate_image_attachment(:cover_image)
  end

  def profile_picture_validation
    validate_image_attachment(:profile_picture)
  end

  def validate_image_attachment(attr)
    attachment = send(attr)
    return unless attachment.attached?

    unless attachment.blob.content_type.in?(%w[image/jpeg image/png image/webp image/svg+xml])
      attachment.purge
      errors.add(attr, I18n.t("shelters.errors.#{attr}_invalid_type", default: I18n.t("shelters.errors.image_invalid_type")))
      return
    end

    if attachment.blob.byte_size > 5.megabytes
      attachment.purge
      errors.add(attr, I18n.t("shelters.errors.#{attr}_too_large", default: I18n.t("shelters.errors.image_too_large")))
    end
  end
end

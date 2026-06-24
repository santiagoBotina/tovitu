class Shelter < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, dependent: :destroy
  has_many :pets, dependent: :restrict_with_error
  has_many :adoption_applications, dependent: :restrict_with_error
  has_many :ai_documents, class_name: "Ai::Document", dependent: :destroy

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

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :discarded, -> { where.not(discarded_at: nil) }
  scope :undiscarded, -> { where(discarded_at: nil) }

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
end

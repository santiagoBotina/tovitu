class AdoptionRequest < ApplicationRecord
  belongs_to :pet
  belongs_to :adopter, class_name: "User"
  belongs_to :shelter
  has_many :timeline_events, class_name: "AdoptionRequestTimelineEvent", dependent: :destroy

  enum :status, { pending: "pending", in_validation: "in_validation",
                  accepted: "accepted", declined: "declined" }

  validates :adopter_id, uniqueness: { scope: :pet_id,
    message: ->(obj, data) { I18n.t("adoptions.requests.errors.duplicate") },
    conditions: -> { where.not(status: :declined) } }

  scope :active, -> { where.not(status: :declined) }
  scope :by_shelter, ->(shelter_id) { where(shelter_id: shelter_id) }
  scope :by_adopter, ->(adopter_id) { where(adopter_id: adopter_id) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :newest_first, -> { order(created_at: :desc) }

  def record_timeline!(from_status:, to_status:, actor: nil, metadata: {})
    timeline_events.create!(
      from_status: from_status,
      to_status: to_status,
      actor: actor,
      metadata: metadata
    )
  end

  def available_for_review?
    pending? || in_validation?
  end
end

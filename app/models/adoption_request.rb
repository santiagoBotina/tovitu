class AdoptionRequest < ApplicationRecord
  belongs_to :pet
  belongs_to :adopter, class_name: "User"
  belongs_to :shelter, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :timeline_events, class_name: "AdoptionRequestTimelineEvent", dependent: :destroy

  enum :status, { pending: "pending", in_validation: "in_validation",
                  accepted: "accepted", declined: "declined",
                  withdrawn: "withdrawn" }

  validates :adopter_id, uniqueness: { scope: :pet_id,
    message: ->(obj, data) { I18n.t("adoptions.requests.errors.duplicate") },
    conditions: -> { where.not(status: [ :declined, :withdrawn ]) } }

  scope :active, -> { where.not(status: [ :declined, :withdrawn ]) }
  scope :by_shelter, ->(shelter_id) { where(shelter_id: shelter_id) }
  scope :by_adopter, ->(adopter_id) { where(adopter_id: adopter_id) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :newest_first, -> { order(created_at: :desc) }
  scope :with_additional_answers, -> { where.not(additional_answers: {}) }
  scope :without_additional_answers, -> { where(additional_answers: {}).or(where(additional_answers: nil)) }

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

  def withdrawable?
    pending? || in_validation?
  end

  def responsible_party
    shelter || pet.publisher
  end

  def individual_publisher?
    shelter_id.nil? && pet.publisher.present?
  end

  def responsible_party_name
    if shelter.present?
      shelter.name
    else
      pet.publisher&.name
    end
  end

  def responsible_party_email
    if shelter.present?
      shelter.users.undiscarded.where(role: %w[shelter_admin shelter_staff]).first&.email
    else
      pet.publisher&.email
    end
  end

  def status_badge
    ActionController::Base.render(
      partial: "adoption_requests/status_badge",
      locals: { status: status },
      formats: [ :html ]
    )
  end

  def self.pending_for_publisher(publisher)
    joins(:pet).where(pets: { publisher_id: publisher.id }, status: :pending)
  end
end

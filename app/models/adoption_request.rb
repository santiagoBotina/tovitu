class AdoptionRequest < ApplicationRecord
  belongs_to :pet
  belongs_to :adopter, class_name: "User"
  belongs_to :shelter, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :timeline_events, class_name: "AdoptionRequestTimelineEvent", dependent: :destroy

  enum :status, { pending: "pending", in_validation: "in_validation",
                  accepted: "accepted", declined: "declined",
                  withdrawn: "withdrawn" }

  after_create_commit :enqueue_adopter_insight_generation

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

  # Decline reasons are stored in the timeline-event metadata by
  # Adoptions::DeclineRequest. Expose them so mailers and views can render them
  # without parsing timeline events themselves (plan 32, problem 11).
  def decline_reasons
    event = timeline_events.order(created_at: :desc).find do |e|
      e.metadata.is_a?(Hash) && e.metadata["decline_reasons"].present?
    end
    event&.metadata&.dig("decline_reasons")
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

  # True when the pet-fit summary was computed from an older snapshot of the
  # adopter's signals than the one currently cached. Signals changed after
  # generation (e.g. new saved pet / request) → the summary is stale.
  def pet_fit_stale?
    return false if pet_fit_signal_fingerprint.blank?

    insight = adopter.adopter_insight
    return false if insight.nil? || insight.signal_fingerprint.blank?

    pet_fit_signal_fingerprint != insight.signal_fingerprint
  end

  private

  def enqueue_adopter_insight_generation
    Ai::GenerateAdopterInsightJob.perform_later(request_id: id)
  end
end

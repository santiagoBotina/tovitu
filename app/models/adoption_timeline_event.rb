class AdoptionTimelineEvent < ApplicationRecord
  EVENT_TYPES = %w[
    created approved rejected info_requested info_received
    completed withdrawn cancelled expired
  ].freeze

  belongs_to :adoption_application, touch: true

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  scope :chronological, -> { order(created_at: :asc) }
  scope :reverse_chronological, -> { order(created_at: :desc) }
  scope :since, ->(time) { where(created_at: time..) }
end

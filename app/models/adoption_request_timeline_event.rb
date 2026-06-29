class AdoptionRequestTimelineEvent < ApplicationRecord
  belongs_to :adoption_request
  belongs_to :actor, class_name: "User", optional: true

  scope :chronological, -> { order(created_at: :asc) }
end

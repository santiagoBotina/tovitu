class AdoptionNote < ApplicationRecord
  belongs_to :adoption_application, touch: true
  belongs_to :user

  validates :content, presence: true

  scope :pinned_first, -> { order(pinned: :desc, created_at: :desc) }
  scope :pinned,       -> { where(pinned: true) }
  scope :unpinned,     -> { where(pinned: false) }
end

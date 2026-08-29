class FavoritesImport < ApplicationRecord
  STATUSES = %w[pending completed failed].freeze

  belongs_to :user

  validates :status, inclusion: { in: STATUSES }
  validates :requested_ids, presence: true

  scope :latest, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end
end

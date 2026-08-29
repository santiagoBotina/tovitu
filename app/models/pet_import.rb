# Tracks a shelter's batch pet import (CSV/Excel). The record is the
# server-side source of truth for async progress and the persisted result
# summary, so a shelter staff member can start a large import, leave the page,
# and return later to review the outcome.
class PetImport < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  belongs_to :shelter
  belongs_to :user
  has_one_attached :file

  validates :status, inclusion: { in: STATUSES }
  validates :file_name, presence: true

  scope :latest, -> { order(created_at: :desc) }

  def pending?
    status == "pending" || status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def imported_rows
    summary["imported"] || []
  end

  def duplicate_rows
    summary["duplicates"] || []
  end

  def error_rows
    summary["errors"] || []
  end
end

class UserLocation < ApplicationRecord
  belongs_to :user

  SOURCES = %w[device manual].freeze

  validates :city, presence: true
  validates :source, inclusion: { in: SOURCES }

  def device?
    source == "device"
  end

  def manual?
    source == "manual"
  end
end

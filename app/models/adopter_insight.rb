class AdopterInsight < ApplicationRecord
  TTL = 24.hours

  belongs_to :adopter, class_name: "User"

  scope :fresh, -> { where.not(generated_at: nil).where("generated_at >= ?", TTL.ago) }

  def fresh_for?(fingerprint)
    generated_at.present? &&
      generated_at >= TTL.ago &&
      signal_fingerprint == fingerprint
  end

  def data
    super || {}
  end
end

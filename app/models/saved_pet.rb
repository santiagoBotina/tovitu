class SavedPet < ApplicationRecord
  belongs_to :user
  belongs_to :pet

  validates :user_id, uniqueness: { scope: :pet_id }

  after_commit :refresh_adopter_insight, on: :create

  private

  def refresh_adopter_insight
    Ai::GenerateAdopterInsightJob.perform_later(adopter_id: user_id)
  end
end

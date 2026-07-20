class IndividualProfile < ApplicationRecord
  self.table_name = "individual_profiles"

  belongs_to :user

  validates :user, presence: true
  validates :activity_level, inclusion: {
    in: %w[very_calm mostly_calm balanced active very_active],
    allow_blank: true
  }
  validates :ideal_companion, inclusion: {
    in: %w[calm_friend playful_companion affectionate_pet independent_pet social_pet],
    allow_blank: true
  }
  validates :pet_experience, inclusion: {
    in: %w[first_time some_experience years_of_experience very_experienced],
    allow_blank: true
  }
  validates :daily_time_available, inclusion: {
    in: %w[less_than_1h 1_to_2h 2_to_4h more_than_4h],
    allow_blank: true
  }
  validates :personality, inclusion: {
    in: %w[calm_thoughtful friendly_social adventurous_energetic organized_routine flexible_spontaneous],
    allow_blank: true
  }
  validates :adoption_priority, length: { maximum: 200 }, allow_blank: true
end

class ShelterProfile < ApplicationRecord
  belongs_to :user
  belongs_to :shelter, optional: true

  validates :user, presence: true
  validates :organization_type, inclusion: {
    in: %w[small_rescue independent_shelter large_shelter ngo_foundation foster_based],
    allow_blank: true
  }
  validates :pet_count_range, inclusion: {
    in: %w[under_20 20_to_50 50_to_100 over_100],
    allow_blank: true
  }
  validates :adoption_involvement, inclusion: {
    in: %w[basic_screening interviews extensive_matching long_term_support],
    allow_blank: true
  }
  validates :approval_philosophy, length: { maximum: 200 }, allow_blank: true
end

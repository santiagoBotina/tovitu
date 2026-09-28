class IndividualProfile < ApplicationRecord
  self.table_name = "individual_profiles"

  HOME_ENVIRONMENTS = %w[house_with_fenced_yard house_without_fenced_yard
                         apartment_or_condo other_home].freeze
  OTHER_PETS_OPTIONS = %w[no_other_pets has_dogs has_cats has_other_animals].freeze
  # Plan-49 structured fields that unlock age / fenced-yard / other-pet rules.
  EVALUATION_FIELDS = %i[date_of_birth home_environment other_pets].freeze

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
  validates :home_environment, inclusion: { in: HOME_ENVIRONMENTS, allow_blank: true }
  validates :other_pets, inclusion: { in: OTHER_PETS_OPTIONS, allow_blank: true }
  validates :date_of_birth, comparison: { less_than_or_equal_to: Date.current,
    message: ->(_obj, _data) { I18n.t("errors.onboarding.invalid_date_of_birth") } },
    allow_blank: true

  # Derived age (years) used for minimum-age rules and the under-18 system
  # rule. Shelters always see this derived value — never the raw DOB.
  def age_years
    return if date_of_birth.blank?

    now = Date.current
    age = now.year - date_of_birth.year
    age -= 1 if now < date_of_birth + age.years
    age
  end

  def has_other_pets?
    other_pets.present? && other_pets != "no_other_pets"
  end

  # Fraction (0..1) of the mandatory onboarding questions the adopter has
  # answered. Used by the profile-completeness rules and system rule.
  def profile_completeness
    fields = total_onboarding_questions
    return 0.0 if fields.zero?

    onboarding_answer_count.to_f / fields
  end

  def total_onboarding_questions
    Onboarding::Individual::SaveResponse::QUESTION_FIELDS.size
  end

  def onboarding_answer_count
    Onboarding::Individual::SaveResponse::QUESTION_FIELDS.values.count do |field|
      value = self[field]
      value.present? && !(value.is_a?(Array) && value.empty?)
    end
  end

  # The plan-49 structured fields that unlock age / fenced-yard / other-pet
  # rules. Existing adopters who finished onboarding before these existed are
  # never blocked, but they are gently prompted to complete them.
  def missing_evaluation_fields
    EVALUATION_FIELDS.select { |field| self[field].blank? }
  end
end

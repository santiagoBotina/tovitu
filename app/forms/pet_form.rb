class PetForm < ApplicationForm
  attr_accessor :name, :species, :breed, :age_category, :birth_date,
                :size, :sex, :description, :personality_traits,
                :medical_notes, :spayed_neutered, :vaccinated, :special_needs,
                :good_with_children, :good_with_dogs, :good_with_cats,
                :requirements, :photos, :pet, :shelter

  validates :name,         presence: true
  validates :species,      presence: true, inclusion: { in: Pet::SPECIES }
  validates :age_category, presence: true, inclusion: { in: Pet::AGE_CATEGORIES }
  validates :sex,          presence: true, inclusion: { in: Pet::SEXES }
  validates :size,         inclusion: { in: Pet::SIZES, allow_blank: true }

  validate :at_least_one_photo, on: :create

  def initialize(attributes = {})
    @photos             = []
    @personality_traits = []
    super(attributes)
  end

  def persist
    return false unless valid?

    if pet
      update_pet
    else
      create_pet
    end
  end

  private

  def create_pet
    result = Pets::Create.call(shelter: shelter, params: pet_params, photos: photos)
    @pet = result.data if result.success?
    result.success?
  end

  def update_pet
    result = Pets::Update.call(pet: pet, params: pet_params)
    @pet.reload if result.success?
    result.success?
  end

  def pet_params
    {
      name:                name,
      species:             species,
      breed:               breed.presence,
      age_category:        age_category,
      birth_date:          birth_date.presence,
      size:                size.presence,
      sex:                 sex,
      description:         description.presence,
      personality_traits:  Array(personality_traits),
      medical_notes:       medical_notes.presence,
      spayed_neutered:     cast_bool(spayed_neutered),
      vaccinated:          cast_bool(vaccinated),
      special_needs:       cast_bool(special_needs),
      good_with_children:  cast_bool(good_with_children),
      good_with_dogs:      cast_bool(good_with_dogs),
      good_with_cats:      cast_bool(good_with_cats),
      requirements:        requirements.presence
    }
  end

  def cast_bool(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def at_least_one_photo
    errors.add(:photos, I18n.t("pets.errors.no_photos")) if photos.blank?
  end
end

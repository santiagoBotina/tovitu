module PetsHelper
  def pet_species_options
    Pet::SPECIES.map { |s| [ t("pets.species.#{s}"), s ] }
  end

  def pet_age_category_options
    Pet::AGE_CATEGORIES.map { |a| [ t("pets.age_categories.#{a}"), a ] }
  end

  def pet_size_options
    Pet::SIZES.map { |s| [ t("pets.sizes.#{s}"), s ] }
  end

  def pet_sex_options
    Pet::SEXES.map { |s| [ t("pets.sex.#{s}"), s ] }
  end

  def pet_status_options
    Pet::STATUSES.map { |s| [ t("pets.status.#{s}"), s ] }
  end
end

module PetsHelper
  def parse_daily_routine(input)
    return nil if input.blank?
    return input if input.is_a?(Hash)

    parsed = JSON.parse(input) rescue nil
    return parsed if parsed.is_a?(Hash)

    input.to_s
  end

  def pet_species_options
    Pet::SPECIES.map { |s| [ t("pets.species.#{s}"), s ] }
  end

  def pet_age_category_options
    Pet::AGE_CATEGORIES.map { |cat| [ t("pets.age_categories.#{cat}"), cat ] }
  end

  def pet_size_options
    Pet::SIZES.map { |s| [ t("pets.sizes.#{s}"), s ] }
  end

  def pet_sex_options
    Pet::SEXES.map { |s| [ t("pets.sex.#{s}"), s ] }
  end

  def life_preview_icon_path(pet)
    case pet.species
    when "dog" then "/icons/dog.svg"
    when "cat" then "/icons/cat.svg"
    else "/icons/balloon.svg"
    end
  end

  def pet_saved?(pet)
    if signed_in?
      return false unless current_user.respond_to?(:saved_pets)
      current_user.saved_pets.exists?(pet_id: pet.id)
    else
      (session[:saved_pet_ids] || []).include?(pet.id)
    end
  end

  def saved_pets_count
    if signed_in?
      current_user.saved_pets.count
    else
      (session[:saved_pet_ids] || []).length
    end
  end

  # Human summary for a completed favorites import. When every requested pet
  # was imported the plain "N saved pets were added" copy is used; when some
  # were skipped (e.g. no longer available) the summary communicates "N of M
  # imported" so the user understands nothing was silently lost.
  def favorites_import_summary(import)
    imported = import.imported_count
    total = import.total_count

    if imported.zero?
      t("saved_pets.import.imported_none")
    elsif imported < total
      if imported == 1
        t("saved_pets.import.imported_partial_one", total: total)
      else
        t("saved_pets.import.imported_partial_other", count: imported, total: total)
      end
    elsif imported == 1
      t("saved_pets.import.imported_one")
    else
      t("saved_pets.import.imported_other", count: imported)
    end
  end
end

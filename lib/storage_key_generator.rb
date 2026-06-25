module StorageKeyGenerator
  module_function

  def pet_photo(shelter_name, pet_name)
    "#{slug_for(shelter_name)}/pets/#{slug_for(pet_name)}/#{random_key}"
  end

  def shelter_logo(shelter_name)
    "#{slug_for(shelter_name)}/logo/#{random_key}"
  end

  def shelter_cover(shelter_name)
    "#{slug_for(shelter_name)}/cover/#{random_key}"
  end

  def shelter_profile(shelter_name)
    "#{slug_for(shelter_name)}/profile/#{random_key}"
  end

  def ai_document(shelter_name)
    "#{slug_for(shelter_name)}/documents/#{random_key}"
  end

  def random_key
    SecureRandom.base36(28)
  end

  def slug_for(name)
    name.to_s.parameterize.presence || "unnamed"
  end
end

module PetsHelper
  def parse_daily_routine(input)
    return nil if input.blank?
    return input if input.is_a?(Hash)

    parsed = JSON.parse(input) rescue nil
    return normalize_daily_routine(parsed) if parsed.is_a?(Array)
    return parsed if parsed.is_a?(Hash)
    return normalize_daily_routine(input) if input.is_a?(Array)

    input.to_s
  end

  # The AI may return the daily routine as an array of "time: description"
  # strings (["6:00 PM: Verificar que...", ...]). Normalize each entry into a
  # { time_period => description } hash so the view renders one card per block
  # and the chronological sorter works. Entries without a time prefix fall
  # back to a numbered label so nothing is lost.
  def normalize_daily_routine(entries)
    return entries if entries.is_a?(Hash)

    routine = {}
    Array(entries).each_with_index do |entry, idx|
      time, description = split_routine_entry(entry.to_s)
      if description.present?
        routine[time.strip] = description.strip
      else
        routine["#{I18n.t('pets.show.daily_routine')} #{idx + 1}"] = entry.to_s.strip
      end
    end
    routine
  end

  # Splits "6:00 PM: Verificar que..." into ["6:00 PM", "Verificar que..."].
  # Matches a leading 12h/24h clock so "6:00" is not mistaken for the
  # delimiter; falls back to splitting on the first colon.
  def split_routine_entry(entry)
    if (match = entry.match(/^(\d{1,2}:\d{2}\s*(?:AM|PM)?)\s*:\s*(.+)$/i))
      [ match[1], match[2] ]
    else
      entry.split(/:\s*/, 2)
    end
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

  # Returns the SVG icon path for the life preview header. Dog and cat have
  # dedicated icons; every other species falls back to nil so the view can
  # render the species emoji instead of a generic "other" balloon.
  def life_preview_icon_path(pet)
    case pet.species
    when "dog" then "/icons/dog.svg"
    when "cat" then "/icons/cat.svg"
    end
  end

  # The AI returns tip categories as snake_case keys ("home_preparation",
  # "supplies", ...). We localize the ones we know via i18n and fall back to a
  # humanized key for anything the model invented, so the section never shows
  # hardcoded English titles.
  def life_preview_tip_category_label(category)
    normalized = category.to_s.downcase
    key = case normalized
          when /home|space|environment/ then :home_preparation
          when /suppl|gear|essentials/ then :supplies
          when /family|household|member/ then :family_preparation
          when /lifestyle|schedule|routine|adjust/ then :lifestyle_adjustments
          when /train|behavior|social/ then :training_resources
          when /food|feed|nutrition/ then :feeding
          when /health|vet|medical/ then :health
          when /safe|safety/ then :safety
          when /bond|love|care|affection/ then :bonding
          end
    return category.to_s.humanize if key.nil?
    I18n.t("pets.show.life_preview_tip_categories.#{key}", default: category.to_s.humanize)
  end

  # Visual treatment for one daily-routine time block: a time-of-day emoji plus
  # tinted card/chip classes. Matches both the English keys the prompt
  # encourages and Spanish keys the AI may emit for es users; unknown periods
  # cycle through a palette by index so the section never collapses to a single
  # repeated icon.
  def life_preview_time_block_style(time_period, index)
    normalized = time_period.to_s.downcase
    matched = case normalized
              when /morning|early|mañana|manana|madrugada|desayuno/ then { icon: "☀️", card: "bg-accent-yellow/15 border-accent-yellow/40", chip: "bg-accent-yellow/30" }
              when /\bmidday\b|\bnoon\b|\blunch\b|almuerzo|comida|mediodía|mediodia/ then { icon: "🍽️", card: "bg-accent-orange/15 border-accent-orange/40", chip: "bg-accent-orange/30" }
              when /afternoon|tarde/ then { icon: "🌤️", card: "bg-secondary-50 border-secondary-200/70", chip: "bg-secondary-100" }
              when /evening|atardecer|cena/ then { icon: "🌅", card: "bg-accent-pink/15 border-accent-pink/40", chip: "bg-accent-pink/20" }
              when /night|noche|dormir|descanso/ then { icon: "🌙", card: "bg-primary-50 border-primary-200/70", chip: "bg-primary-100" }
              when /walk|paseo|ejercicio|exercise/ then { icon: "🚶", card: "bg-secondary-50 border-secondary-200/70", chip: "bg-secondary-100" }
              when /play|juego|enrichment/ then { icon: "🎾", card: "bg-accent-pink/15 border-accent-pink/40", chip: "bg-accent-pink/20" }
              when /groom|aseo|cepillado/ then { icon: "🛁", card: "bg-primary-50 border-primary-200/70", chip: "bg-primary-100" }
              end
    return matched if matched

    palette = [
      { icon: "⭐", card: "bg-accent-yellow/15 border-accent-yellow/40", chip: "bg-accent-yellow/30" },
      { icon: "🌤️", card: "bg-secondary-50 border-secondary-200/70", chip: "bg-secondary-100" },
      { icon: "🌙", card: "bg-primary-50 border-primary-200/70", chip: "bg-primary-100" },
      { icon: "🍽️", card: "bg-accent-orange/15 border-accent-orange/40", chip: "bg-accent-orange/30" },
      { icon: "🌅", card: "bg-accent-pink/15 border-accent-pink/40", chip: "bg-accent-pink/20" }
    ]
    palette[index % palette.length]
  end

  # Ranks a time-period key so the daily routine can be presented in a natural
  # chronological order (morning → midday → afternoon → evening → night).
  # Unknown keys sort to the end, keeping their original relative order.
  TIME_PERIOD_RANKS = [
    [ /morning|early|mañana|manana|madrugada|desayuno|breakfast/, 0 ],
    [ /\bmidday\b|\bnoon\b|\blunch\b|almuerzo|comida|mediodía|mediodia/, 1 ],
    [ /afternoon|tarde/, 2 ],
    [ /evening|atardecer|cena/, 3 ],
    [ /night|noche|dormir|descanso/, 4 ]
  ].freeze

  def life_preview_time_period_rank(period)
    normalized = period.to_s.downcase
    TIME_PERIOD_RANKS.each { |regex, rank| return rank if normalized.match?(regex) }
    99
  end

  # Returns the daily routine hash sorted by time of day. Stable so any keys
  # the AI invents keep their original order once the known periods are placed.
  def life_preview_sorted_daily_routine(daily_routine)
    return daily_routine unless daily_routine.is_a?(Hash)
    entries = daily_routine.to_a
    sorted = entries.each_with_index.sort_by { |(period, _), idx| [ life_preview_time_period_rank(period), idx ] }
    sorted.map(&:first)
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

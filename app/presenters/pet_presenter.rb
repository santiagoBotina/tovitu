class PetPresenter < ApplicationPresenter
  include Rails.application.routes.url_helpers

  def age_display
    if model.birth_date.present?
      age = compute_years
      I18n.t("pets.age_display",
             category: I18n.t("pets.age_categories.#{model.age_category}"),
             age: age,
             count: age)
    else
      I18n.t("pets.age_categories.#{model.age_category}")
    end
  end

  def primary_photo_url(variant: :medium)
    photo = model.primary_photo
    return placeholder_photo_url unless photo

    if photo.blob.content_type == "image/svg+xml"
      return rails_blob_path(photo, only_path: true)
    end

    rails_representation_path(Pets::PhotoVariants.for(photo, variant), only_path: true)
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ActiveStorage::InvariableError
    placeholder_photo_url
  end

  def photo_gallery(variant: :thumb)
    model.ordered_photos.map do |photo|
      if photo.blob.content_type == "image/svg+xml"
        next rails_blob_path(photo, only_path: true)
      end

      rails_representation_path(Pets::PhotoVariants.for(photo, variant), only_path: true)
    end
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ActiveStorage::InvariableError
    []
  end

  def status_badge
    ActionController::Base.render(
      partial: "pets/status_badge",
      locals: { status: model.status },
      formats: [ :html ]
    )
  end

  def requirements_list
    return [] if model.requirements.blank?
    model.requirements.split("\n").map(&:strip).reject(&:blank?)
  end

  def species_label
    I18n.t("pets.species.#{model.species}")
  end

  def species_emoji
    Pet::SPECIES_EMOJI.fetch(model.species, Pet::SPECIES_EMOJI["other"])
  end

  def sex_label
    I18n.t("pets.sex.#{model.sex}")
  end

  def size_label
    model.size.present? ? I18n.t("pets.sizes.#{model.size}") : nil
  end

  def personality_traits_list
    Array(model.personality_traits)
  end

  # Localized "ideal home" fit tags derived from structured data. Empty when
  # no fit signals are available, so the section can degrade honestly.
  def ideal_home_fit_list
    fits = []
    fits << I18n.t("pets.show.compatibility_fit_apartment") if model.size.in?(%w[small medium])
    fits << I18n.t("pets.show.compatibility_fit_spacious") if model.size.in?(%w[large giant])
    fits << I18n.t("pets.show.compatibility_fit_kids") if model.good_with_children?
    fits << I18n.t("pets.show.compatibility_fit_dogs") if model.good_with_dogs?
    fits << I18n.t("pets.show.compatibility_fit_cats") if model.good_with_cats?
    fits
  end

  # Plain-text shelter/publisher recommendation, re-sanitized at read time as
  # defense in depth. nil/blank -> section hidden on the profile.
  def recommendation
    Pets::Recommendation.sanitize(model.recommendation)
  end

  # The "shelter voice" for this pet: the shelter for shelter-listed pets, the
  # publisher for individually-listed pets.
  def recommendation_author
    model.shelter&.name.presence || model.publisher&.name.presence
  end

  def recommendation_author_kind
    model.shelter_listed? ? :shelter : :individual
  end

  def life_preview_available?
    model.life_preview_data.present?
  end

  def life_preview_stale?
    model.life_preview_stale?
  end

  def life_preview_age
    return nil unless model.life_preview_generated_at
    time_ago_in_words(model.life_preview_generated_at)
  end

  # Display dimensions (width, height) for a variant, used as width/height
  # hints on <img> tags to prevent layout shift. Matches the aspect ratio of
  # the containers the variant is rendered in.
  def variant_dimensions(variant)
    Pets::PhotoVariants.display_dimensions(variant)
  end

  private

  def compute_years
    now = Time.current.utc.to_date
    bd  = model.birth_date
    now.year - bd.year - ((now.month > bd.month || (now.month == bd.month && now.day >= bd.day)) ? 0 : 1)
  end

  def placeholder_photo_url
    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='300' viewBox='0 0 400 300'%3E%3Crect width='400' height='300' fill='%23f5f5f4'/%3E%3Ccircle cx='200' cy='130' r='50' fill='%23d6d3d1'/%3E%3Cpath d='M100 250c0-55 45-100 100-100s100 45 100 100' fill='%23d6d3d1'/%3E%3C/svg%3E"
  end
end

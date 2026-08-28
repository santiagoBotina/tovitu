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

    dimension = variant_dimensions(variant)
    rails_representation_path(photo.variant(resize_to_limit: dimension), only_path: true)
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ActiveStorage::InvariableError
    placeholder_photo_url
  end

  def photo_gallery(variant: :thumb)
    model.ordered_photos.map do |photo|
      if photo.blob.content_type == "image/svg+xml"
        next rails_blob_path(photo, only_path: true)
      end

      dimension = variant_dimensions(variant)
      rails_representation_path(photo.variant(resize_to_limit: dimension), only_path: true)
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

  def sex_label
    I18n.t("pets.sex.#{model.sex}")
  end

  def size_label
    model.size.present? ? I18n.t("pets.sizes.#{model.size}") : nil
  end

  def personality_traits_list
    Array(model.personality_traits)
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

  private

  def compute_years
    now = Time.current.utc.to_date
    bd  = model.birth_date
    now.year - bd.year - ((now.month > bd.month || (now.month == bd.month && now.day >= bd.day)) ? 0 : 1)
  end

  def variant_dimensions(variant)
    case variant.to_sym
    when :thumb  then [ 150, 150 ]
    when :medium then [ 400, 400 ]
    when :large  then [ 1200, 1200 ]
    else [ 400, 400 ]
    end
  end

  def placeholder_photo_url
    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='300' viewBox='0 0 400 300'%3E%3Crect width='400' height='300' fill='%23f5f5f4'/%3E%3Ccircle cx='200' cy='130' r='50' fill='%23d6d3d1'/%3E%3Cpath d='M100 250c0-55 45-100 100-100s100 45 100 100' fill='%23d6d3d1'/%3E%3C/svg%3E"
  end
end

class ShelterPresenter < ApplicationPresenter
  include Rails.application.routes.url_helpers

  def logo_url(variant: :thumb)
    return nil unless model.logo.attached?
    variant_url(model.logo, variant)
  end

  def cover_url(variant: :large)
    return nil unless model.cover_image.attached?
    variant_url(model.cover_image, variant)
  end

  def profile_picture_url(variant: :medium)
    return nil unless model.profile_picture.attached?
    variant_url(model.profile_picture, variant)
  end

  private

  def variant_url(attachment, variant)
    if attachment.blob.content_type == "image/svg+xml"
      return rails_blob_path(attachment, only_path: true)
    end

    dimension = case variant.to_sym
    when :thumb  then [ 100, 100 ]
    when :medium then [ 200, 200 ]
    when :large  then [ 400, 400 ]
    when :xlarge then [ 1200, 400 ]
    else [ 200, 200 ]
    end

    rails_representation_path(
      attachment.variant(resize_to_limit: dimension, format: :webp, saver: { quality: 80 }),
      only_path: true
    )
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ActiveStorage::InvariableError
    nil
  end

  def default_url_options
    { locale: I18n.locale }
  end

  public

  def address
    "#{model.street}, #{model.city}, #{model.state} #{model.zip}"
  end

  def status_badge
    if model.active?
      "<span class=\"inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-50 text-green-700\"><span class=\"w-1.5 h-1.5 rounded-full bg-green-500\"></span>#{I18n.t('presenters.shelter.status_active')}</span>".html_safe
    else
      "<span class=\"inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-neutral-50 text-neutral-500\"><span class=\"w-1.5 h-1.5 rounded-full bg-neutral-400\"></span>#{I18n.t('presenters.shelter.status_inactive')}</span>".html_safe
    end
  end

  def species_display
    model.species_served.map(&:capitalize).to_sentence
  end

  # Presentation metadata for each onboarding step. The "is this step done?"
  # conditions live in Shelters::OnboardingChecklist so domain services and the
  # dashboard agree on completion; STEPS_CONFIG only carries icon/path details.
  STEPS_CONFIG = [
    {
      key: :add_pet,
      icon: "M12 5v14m-7-7h14",
      category: :pets,
      manage_only: false,
      path_method: :new_shelter_pet_path,
      path_args: ->(shelter) { {} }
    },
    {
      key: :policies,
      icon: "M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z",
      category: :operations,
      manage_only: true,
      path_method: :edit_shelter_policies_path,
      path_args: ->(shelter) { { shelter_id: shelter } }
    },
    {
      key: :staff,
      icon: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z",
      category: :team,
      manage_only: true,
      path_method: :shelter_staff_index_path,
      path_args: ->(shelter) { { shelter_id: shelter } }
    },
    {
      key: :hours,
      icon: "M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z",
      category: :operations,
      manage_only: true,
      path_method: :edit_shelter_path,
      path_args: ->(shelter) { { id: shelter } }
    },
    {
      key: :profile,
      icon: "M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z",
      category: :profile,
      manage_only: true,
      path_method: :edit_shelter_path,
      path_args: ->(shelter) { { id: shelter } }
    },
    {
      key: :publish,
      icon: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
      category: :visibility,
      manage_only: true,
      path_method: :edit_shelter_path,
      path_args: ->(shelter) { { id: shelter } }
    }
  ].freeze

  def onboarding_checklist
    @onboarding_checklist ||= Shelters::OnboardingChecklist.new(model)
  end

  def onboarding_progress
    total = onboarding_checklist.total_count
    done = onboarding_checklist.done_count
    ((done.to_f / total) * 100).to_i
  end

  def onboarding_steps
    STEPS_CONFIG.map do |step|
      done = onboarding_checklist.step_done?(step[:key])
      {
        key: step[:key],
        label: I18n.t("presenters.shelter.onboarding.#{step[:key]}"),
        description: I18n.t("onboarding.shelter.checklist.step.#{step[:key]}.description", default: ""),
        icon: step[:icon],
        category: step[:category],
        manage_only: step[:manage_only],
        done: done,
        path: send(step[:path_method], **step[:path_args].call(model))
      }
    end
  end

  def checklist_completed?
    onboarding_checklist.completed?
  end

  def checklist_dismissed?
    onboarding_checklist.dismissed?
  end

  def checklist_level
    done_count = onboarding_checklist.done_count
    case done_count
    when 0
      { level: 1, title: I18n.t("onboarding.shelter.checklist.level.new_recruit"), badge: :bronze, color_class: "text-amber-700 bg-amber-50 border-amber-200" }
    when 1..2
      { level: 2, title: I18n.t("onboarding.shelter.checklist.level.getting_ready"), badge: :silver, color_class: "text-neutral-600 bg-neutral-100 border-neutral-300" }
    when 3..4
      { level: 3, title: I18n.t("onboarding.shelter.checklist.level.almost_there"), badge: :gold, color_class: "text-yellow-700 bg-yellow-50 border-yellow-200" }
    when 5
      { level: 4, title: I18n.t("onboarding.shelter.checklist.level.ready_to_rescue"), badge: :purple, color_class: "text-primary-700 bg-primary-50 border-primary-200" }
    when 6
      { level: 5, title: I18n.t("onboarding.shelter.checklist.level.live_and_active"), badge: :teal, color_class: "text-secondary-700 bg-secondary-50 border-secondary-200" }
    end
  end

  def personality_badge
    profile = model.owner&.shelter_profile
    return nil unless profile

    Onboarding::Shelter::Personality.call(profile)
  end
end

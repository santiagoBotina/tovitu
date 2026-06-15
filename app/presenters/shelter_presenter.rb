class ShelterPresenter < ApplicationPresenter
  include Rails.application.routes.url_helpers

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

  def onboarding_progress
    total = 4
    done = 0
    done += 1 if model.description.present?
    done += 1 if model.hours.present?
    done += 1 if model.users.staff.exists?
    done += 1 if model.adoption_policies.values.any?(&:present?)
    ((done.to_f / total) * 100).to_i
  end

  def onboarding_steps
    [
      { label: I18n.t("presenters.shelter.onboarding.add_pet"), done: false, path: "#" },
      { label: I18n.t("presenters.shelter.onboarding.policies"), done: model.adoption_policies.values.any?(&:present?), path: edit_shelter_policies_path(shelter_id: model) },
      { label: I18n.t("presenters.shelter.onboarding.staff"), done: model.users.staff.exists?, path: shelter_staff_index_path(shelter_id: model) },
      { label: I18n.t("presenters.shelter.onboarding.hours"), done: model.hours.present?, path: edit_shelter_path(id: model) },
      { label: I18n.t("presenters.shelter.onboarding.profile"), done: model.description.present?, path: edit_shelter_path(id: model) },
      { label: I18n.t("presenters.shelter.onboarding.publish"), done: model.active?, path: edit_shelter_path(id: model) }
    ]
  end
end

module Shelters
  # Permanently hides a completed onboarding checklist on the shelter dashboard.
  #
  # Guarded: the checklist can only be dismissed once every step is done, so a
  # partially onboarded shelter can never lose the checklist that drives them
  # to completion.
  #
  # Product decision: dismissal is sticky. If a fully onboarded shelter later
  # becomes incomplete again (e.g. its only staff member is removed), the
  # checklist stays hidden and the dashboard keeps showing the restore
  # affordance as a nudge back to completion — we never auto-restore, because
  # dismissing was an explicit admin choice and the restore link is always one
  # click away.
  class DismissChecklist < ApplicationService
    def initialize(shelter:)
      @shelter = shelter
    end

    def call
      checklist = OnboardingChecklist.new(@shelter)

      return Result.failure(I18n.t("errors.shelters.checklist_not_complete")) unless checklist.completed?
      return Result.success(@shelter) if checklist.dismissed?

      @shelter.update!(checklist_dismissed_at: Time.current)
      Result.success(@shelter)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

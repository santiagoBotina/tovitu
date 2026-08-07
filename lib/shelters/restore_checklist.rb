module Shelters
  # Brings a previously dismissed onboarding checklist back on the shelter
  # dashboard. The restore affordance is the escape hatch that prevents owners
  # from losing the checklist entirely after hiding it.
  class RestoreChecklist < ApplicationService
    def initialize(shelter:)
      @shelter = shelter
    end

    def call
      return Result.success(@shelter) unless OnboardingChecklist.new(@shelter).dismissed?

      @shelter.update!(checklist_dismissed_at: nil)
      Result.success(@shelter)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

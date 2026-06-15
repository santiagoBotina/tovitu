module Adoptions
  class FinalizeAdoption < ApplicationService
    def initialize(application:, user:)
      @application = application
      @user        = user
    end

    def call
      return Result.failure(I18n.t("adoptions.errors.not_approved")) unless @application.status == "approved"

      now = Time.current

      ActiveRecord::Base.transaction do
        @application.status       = "completed"
        @application.completed_at = now
        @application.reviewed_by  = @user
        @application.save!

        @application.pet.update!(status: "adopted", adopted_at: now)

        @application.adoption_timeline_events.create!(
          event_type: "completed",
          metadata: {
            completed_by: @user.name,
            completed_at: now
          }
        )
      end

      Result.success(@application)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

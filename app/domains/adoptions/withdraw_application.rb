module Adoptions
  class WithdrawApplication < ApplicationService
    WITHDRAWABLE_STATUSES = %w[pending approved].freeze

    def initialize(application:)
      @application = application
    end

    def call
      unless WITHDRAWABLE_STATUSES.include?(@application.status)
        return Result.failure(
          I18n.t("adoptions.errors.cannot_withdraw",
                 status: StatusMachine.human_status_name(@application.status))
        )
      end

      was_approved = @application.status == "approved"
      now = Time.current

      ActiveRecord::Base.transaction do
        @application.status       = "withdrawn"
        @application.withdrawn_at = now
        @application.save!

        @application.pet.update!(status: "available") if was_approved

        @application.adoption_timeline_events.create!(
          event_type: "withdrawn",
          metadata: {
            was_approved: was_approved,
            withdrawn_at: now
          }
        )
      end

      Result.success(@application)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

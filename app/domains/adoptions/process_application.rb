module Adoptions
  class ProcessApplication < ApplicationService
    ACTIONS = %w[approve reject request_info info_received cancel].freeze

    ACTION_TARGETS = {
      "approve"        => "approved",
      "reject"         => "rejected",
      "request_info"   => "awaiting_response",
      "info_received"  => "under_review",
      "cancel"         => "cancelled"
    }.freeze

    def initialize(application:, action:, user:,
                   rejection_reason: nil, info_requests: nil,
                   cancellation_reason: nil)
      @application        = application
      @action             = action.to_s
      @user               = user
      @rejection_reason   = rejection_reason
      @info_requests      = info_requests
      @cancellation_reason = cancellation_reason
    end

    def call
      return Result.failure(I18n.t("adoptions.errors.invalid_action")) unless ACTIONS.include?(@action)

      target_status = ACTION_TARGETS.fetch(@action)

      unless StatusMachine.transition_allowed?(@application.status, target_status)
        return Result.failure(
          I18n.t("adoptions.errors.invalid_transition",
                 from: StatusMachine.human_status_name(@application.status),
                 to:   StatusMachine.human_status_name(target_status))
        )
      end

      if @action == "reject" && @rejection_reason.blank?
        return Result.failure(I18n.t("adoptions.errors.rejection_reason_required"))
      end

      if @action == "cancel" && @cancellation_reason.blank?
        return Result.failure(I18n.t("adoptions.errors.cancellation_reason_required"))
      end

      if @action == "request_info" && @info_requests.blank?
        return Result.failure(I18n.t("adoptions.errors.info_requests_required"))
      end

      ActiveRecord::Base.transaction do
        @application.status       = target_status
        @application.reviewed_by  = @user

        case @action
        when "approve"
          @application.hold_expires_at = 48.hours.from_now
          @application.save!
          @application.pet.update!(status: "on_hold")
          @application.adoption_timeline_events.create!(
            event_type: "approved",
            metadata: {
              reviewed_by:     @user.name,
              hold_expires_at: @application.hold_expires_at
            }
          )

        when "reject"
          @application.rejection_reason = @rejection_reason
          @application.save!
          @application.adoption_timeline_events.create!(
            event_type: "rejected",
            metadata: {
              reviewed_by: @user.name,
              reason:      @rejection_reason
            }
          )

        when "request_info"
          @application.save!
          @application.adoption_timeline_events.create!(
            event_type: "info_requested",
            metadata: {
              reviewed_by: @user.name,
              questions:   Array(@info_requests)
            }
          )

        when "info_received"
          @application.save!
          @application.adoption_timeline_events.create!(
            event_type: "info_received",
            metadata: { reviewed_by: @user.name }
          )

        when "cancel"
          @application.save!
          @application.pet.update!(status: "available")
          @application.adoption_timeline_events.create!(
            event_type: "cancelled",
            metadata: {
              reviewed_by: @user.name,
              reason:      @cancellation_reason
            }
          )
        end
      end

      Result.success(@application)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

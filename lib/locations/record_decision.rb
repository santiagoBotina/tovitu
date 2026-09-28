module Locations
  class RecordDecision < ApplicationService
    def initialize(user:, decision:)
      @user = user
      @decision = decision
    end

    def call
      # Only (re)record when the decision changes or none is stored yet, so a
      # same-purpose location update does not overwrite the original consent
      # timestamp (REQ-48-4).
      return Result.success if @user.location_decision == @decision && @user.location_decision_at.present?

      @user.update!(
        location_decision: @decision,
        location_disclosure_version: Locations::DISCLOSURE_VERSION,
        location_decision_at: Time.current
      )
      Result.success
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

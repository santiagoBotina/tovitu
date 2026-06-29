module Adoptions
  class DeclineRequest < ApplicationService
    def initialize(request:, actor:, selected_reasons: [], custom_reason: nil)
      @request          = request
      @actor            = actor
      @selected_reasons = Array(selected_reasons).compact
      @custom_reason    = custom_reason.presence
    end

    def call
      all_reasons = @selected_reasons.dup
      all_reasons << @custom_reason if @custom_reason.present?

      if all_reasons.empty?
        return Result.failure([ I18n.t("adoptions.requests.errors.decline_reason_required") ])
      end

      metadata = { decline_reasons: all_reasons }

      result = ProcessRequest.call(
        request: @request,
        new_status: "declined",
        actor: @actor,
        metadata: metadata
      )

      if result.success?
        @request.update_column(:decline_reasons, all_reasons)
        Result.success(@request)
      else
        result
      end
    end
  end
end

module Adoptions
  class ExpireHold < ApplicationService
    def call
      expired_count = 0
      failed_count  = 0

      AdoptionApplication.approved.on_hold_expired.find_each(batch_size: 50) do |application|
        expire_single(application)
        expired_count += 1
      rescue ActiveRecord::RecordInvalid, StandardError => e
        failed_count += 1
        Rails.logger.error "[ExpireHold] Failed to expire application ##{application.id}: #{e.message}"
      end

      if failed_count.positive?
        Rails.logger.warn "[ExpireHold] Completed: #{expired_count} expired, #{failed_count} failed"
      end

      Result.success(expired_count: expired_count, failed_count: failed_count)
    end

    private

    def expire_single(application)
      now = Time.current

      ActiveRecord::Base.transaction do
        application.update!(status: "expired")
        application.pet.update!(status: "available")
        application.adoption_timeline_events.create!(
          event_type: "expired",
          metadata: {
            hold_expired_at: now,
            pet_id:          application.pet_id,
            pet_name:        application.pet.name
          }
        )
      end
    end
  end
end

module Adoptions
  class SubmitRequest < ApplicationService
    def initialize(adopter:, pet:)
      @adopter = adopter
      @pet = pet
    end

    def call
      return Result.failure([ I18n.t("adoptions.requests.errors.onboarding_incomplete") ]) unless @adopter.onboarding_completed?
      return Result.failure([ I18n.t("adoptions.requests.errors.pet_not_available") ]) unless @pet.status_available?

      if existing_active_request?
        return Result.failure([ I18n.t("adoptions.requests.errors.duplicate") ])
      end

      shelter = @pet.shelter
      return Result.failure([ I18n.t("adoptions.requests.errors.shelter_inactive") ]) unless shelter.active?

      request = nil

      AdoptionRequest.transaction do
        request = AdoptionRequest.create!(
          pet: @pet,
          adopter: @adopter,
          shelter: shelter,
          status: :pending
        )

        request.record_timeline!(
          from_status: nil,
          to_status: "pending",
          actor: @adopter,
          metadata: { submitted_via: "web" }
        )
      end

      Result.success(request)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    rescue ActiveRecord::RecordNotUnique
      Result.failure([ I18n.t("adoptions.requests.errors.duplicate") ])
    end

    private

    def existing_active_request?
      AdoptionRequest.where(adopter_id: @adopter.id, pet_id: @pet.id)
                     .where.not(status: :declined)
                     .exists?
    end
  end
end

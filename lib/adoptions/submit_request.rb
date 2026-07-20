module Adoptions
  class SubmitRequest < ApplicationService
    def initialize(adopter:, pet:, additional_answers: {})
      @adopter = adopter
      @pet = pet
      @additional_answers = additional_answers
    end

    def call
      return Result.failure([ I18n.t("adoptions.requests.errors.onboarding_incomplete") ]) unless @adopter.onboarding_completed?
      return Result.failure([ I18n.t("adoptions.requests.errors.pet_not_available") ]) unless @pet.status_available?

      if existing_active_request?
        return Result.failure([ I18n.t("adoptions.requests.errors.duplicate") ])
      end

      shelter = @pet.shelter
      if shelter.present?
        return Result.failure([ I18n.t("adoptions.requests.errors.shelter_inactive") ]) unless shelter.active?
      end

      request = nil

      AdoptionRequest.transaction do
        request = AdoptionRequest.create!(
          pet: @pet,
          adopter: @adopter,
          shelter: shelter,
          status: :pending,
          additional_answers: sanitize_answers(@additional_answers)
        )

        request.record_timeline!(
          from_status: nil,
          to_status: "pending",
          actor: @adopter,
          metadata: { submitted_via: "web" }
        )
      end

      deliver_notifications(request)

      Result.success(request)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    rescue ActiveRecord::RecordNotUnique
      Result.failure([ I18n.t("adoptions.requests.errors.duplicate") ])
    end

    private

    def existing_active_request?
      AdoptionRequest.where(adopter_id: @adopter.id, pet_id: @pet.id)
                     .where.not(status: [:declined, :withdrawn])
                     .exists?
    end

    def sanitize_answers(answers)
      return {} unless answers.is_a?(ActionController::Parameters) || answers.is_a?(Hash)

      permitted = answers.is_a?(ActionController::Parameters) ?
                    answers.permit(:interest_reason, :home_description, :current_pets_details, :something_else) :
                    answers.slice("interest_reason", "home_description", "current_pets_details", "something_else")

      permitted.to_h.select { |_, v| v.present? }
    end

    def deliver_notifications(request)
      party_name = request.responsible_party_name

      # Notify the adopter
      Notifications::Deliver.call(
        recipient: request.adopter,
        actor: nil,
        kind: :request_submitted,
        notifiable: request,
        title: I18n.t("notifications.titles.request_submitted", pet_name: request.pet.name),
        body: I18n.t("notifications.bodies.request_submitted",
                      pet_name: request.pet.name,
                      shelter_name: party_name.to_s),
        action_url: Rails.application.routes.url_helpers.adoption_request_path(id: request.id, locale: I18n.locale),
        metadata: { pet_name: request.pet.name }
      )

      # Notify the responsible party (shelter staff or individual publisher)
      if request.shelter.present?
        request.shelter.users.undiscarded.where(role: %w[shelter_admin shelter_staff]).each do |staff|
          Notifications::Deliver.call(
            recipient: staff,
            actor: request.adopter,
            kind: :request_submitted,
            notifiable: request,
            title: I18n.t("notifications.titles.request_submitted", pet_name: request.pet.name),
            body: I18n.t("notifications.bodies.request_submitted_to_shelter",
                          adopter_name: request.adopter.name,
                          pet_name: request.pet.name),
            action_url: Rails.application.routes.url_helpers.shelter_adoption_request_path(id: request.id, locale: I18n.locale),
            metadata: { pet_name: request.pet.name, adopter_name: request.adopter.name }
          )
        end
      elsif request.individual_publisher?
        publisher = request.pet.publisher
        Notifications::Deliver.call(
          recipient: publisher,
          actor: request.adopter,
          kind: :request_submitted,
          notifiable: request,
          title: I18n.t("notifications.titles.request_submitted", pet_name: request.pet.name),
          body: I18n.t("notifications.bodies.request_submitted_to_publisher",
                        adopter_name: request.adopter.name,
                        pet_name: request.pet.name),
          action_url: Rails.application.routes.url_helpers.my_adoption_request_path(id: request.id, locale: I18n.locale),
          metadata: { pet_name: request.pet.name, adopter_name: request.adopter.name }
        )
      end
    end
  end
end

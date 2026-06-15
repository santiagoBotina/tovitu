module Adoptions
  class CheckStatus < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      application = AdoptionApplication.find_by(token: @token)
      return Result.failure(I18n.t("adoptions.errors.invalid_token")) if application.nil?
      return Result.failure(I18n.t("adoptions.errors.application_not_found")) if application.discarded?

      timeline = build_timeline(application)
      pet      = application.pet
      shelter  = application.shelter

      Result.success(
        reference_number: Adoptions::TokenGenerator.reference(application.token),
        status:           application.status,
        status_label:     StatusMachine.human_status_name(application.status),
        applicant_name:   application.applicant_name,
        submitted_at:     application.created_at,
        updated_at:       application.updated_at,
        pet: {
          name:    pet.name,
          species: pet.species,
          breed:   pet.breed
        },
        shelter: {
          name:  shelter.name,
          phone: shelter.phone,
          city:  shelter.city,
          state: shelter.state
        },
        rejection_reason: application.status_rejected? ? application.rejection_reason : nil,
        timeline:         timeline
      )
    end

    private

    def build_timeline(application)
      application.adoption_timeline_events.order(created_at: :asc).map do |event|
        {
          event_type: event.event_type,
          description: I18n.t("adoptions.timeline.#{event.event_type}",
                              default: event.event_type.humanize),
          occurred_at: event.created_at
        }
      end
    end
  end
end

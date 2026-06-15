module Adoptions
  class SubmitApplication < ApplicationService
    def initialize(pet:, applicant_name:, applicant_email:,
                   applicant_phone: nil, applicant_address: nil,
                   housing_type: nil, current_pets: nil,
                   pet_experience: nil, questionnaire_answers: {})
      @pet                  = pet
      @applicant_name       = applicant_name
      @applicant_email      = applicant_email.to_s.downcase.strip
      @applicant_phone      = applicant_phone
      @applicant_address    = applicant_address
      @housing_type         = housing_type
      @current_pets         = current_pets
      @pet_experience       = pet_experience
      @questionnaire_answers = questionnaire_answers || {}
    end

    def call
      return Result.failure(I18n.t("adoptions.errors.pet_not_available")) unless @pet.status_available?

      if duplicate_exists?
        return Result.failure(I18n.t("adoptions.errors.duplicate_application"))
      end

      application = AdoptionApplication.new(
        pet:                    @pet,
        shelter_id:             @pet.shelter_id,
        applicant_name:         @applicant_name,
        applicant_email:        @applicant_email,
        applicant_phone:        @applicant_phone,
        applicant_address:      @applicant_address,
        housing_type:           @housing_type,
        current_pets:           @current_pets,
        pet_experience:         @pet_experience,
        questionnaire_answers:  @questionnaire_answers,
        token:                  Adoptions::TokenGenerator.generate,
        status:                 "pending"
      )

      ActiveRecord::Base.transaction do
        application.save!

        application.adoption_timeline_events.create!(
          event_type: "created",
          metadata: {
            applicant_email: @applicant_email,
            pet_id:          @pet.id,
            pet_name:        @pet.name
          }
        )
      end

      Result.success(application)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    rescue ActiveRecord::RecordNotUnique
      Result.failure(I18n.t("adoptions.errors.duplicate_application"))
    end

    private

    def duplicate_exists?
      AdoptionApplication.exists?(
        pet_id:          @pet.id,
        applicant_email: @applicant_email
      )
    end
  end
end

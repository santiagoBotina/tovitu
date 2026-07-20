module Adoptions
  class WithdrawRequest < ApplicationService
    def initialize(request:, adopter:)
      @request = request
      @adopter = adopter
    end

    def call
      return Result.failure([ I18n.t("adoptions.requests.errors.cannot_withdraw") ]) unless @request.withdrawable?
      return Result.failure([ I18n.t("adoptions.requests.errors.not_owner") ]) unless @request.adopter_id == @adopter.id

      old_status = @request.status

      AdoptionRequest.transaction do
        @request.update!(
          status: :withdrawn,
          withdrawn_at: Time.current
        )

        @request.record_timeline!(
          from_status: old_status,
          to_status: "withdrawn",
          actor: @adopter,
          metadata: { withdrawn_by: "adopter" }
        )
      end

      # Notify the responsible party
      notify_responsible_party

      Result.success(@request)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    def notify_responsible_party
      party = @request.responsible_party
      return unless party

      case party
      when User
        # Individual publisher
        Notifications::Deliver.call(
          recipient: party,
          actor: @adopter,
          kind: :request_withdrawn,
          notifiable: @request,
          title: I18n.t("notifications.titles.request_withdrawn",
                        pet_name: @request.pet.name,
                        adopter_name: @adopter.name),
          body: I18n.t("notifications.bodies.request_withdrawn",
                       pet_name: @request.pet.name,
                       adopter_name: @adopter.name),
          action_url: Rails.application.routes.url_helpers.my_adoption_request_path(id: @request.id, locale: I18n.locale),
          metadata: { pet_name: @request.pet.name, adopter_name: @adopter.name }
        )
      when ::Shelter
        # Notify all shelter admins/staff
        party.users.undiscarded.where(role: %w[shelter_admin shelter_staff]).each do |staff|
          Notifications::Deliver.call(
            recipient: staff,
            actor: @adopter,
            kind: :request_withdrawn,
            notifiable: @request,
            title: I18n.t("notifications.titles.request_withdrawn",
                          pet_name: @request.pet.name,
                          adopter_name: @adopter.name),
            body: I18n.t("notifications.bodies.request_withdrawn",
                         pet_name: @request.pet.name,
                         adopter_name: @adopter.name),
            action_url: Rails.application.routes.url_helpers.shelter_adoption_request_path(id: @request.id, locale: I18n.locale),
            metadata: { pet_name: @request.pet.name, adopter_name: @adopter.name }
          )
        end
      end
    end
  end
end

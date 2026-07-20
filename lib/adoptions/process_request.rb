module Adoptions
  class ProcessRequest < ApplicationService
    VALID_TRANSITIONS = {
      "pending"       => %w[in_validation accepted declined].freeze,
      "in_validation" => %w[accepted declined].freeze,
      "accepted"      => %w[].freeze,
      "declined"      => %w[].freeze
    }.freeze

    def initialize(request:, new_status:, actor:, metadata: {})
      @request    = request
      @new_status = new_status
      @actor      = actor
      @metadata   = metadata
    end

    def call
      old_status = @request.status

      return Result.failure(
        I18n.t("adoptions.requests.errors.invalid_transition", from: old_status, to: @new_status)
      ) unless valid_transition?(old_status, @new_status)

      AdoptionRequest.transaction do
        @request.update!(
          status: @new_status,
          reviewed_by: @actor,
          reviewed_at: Time.current
        )

        if @new_status == "accepted"
          pet_result = Pets::ChangeStatus.call(pet: @request.pet, new_status: "on_hold")
          unless pet_result.success?
            raise ActiveRecord::RecordInvalid.new(@request)
          end
        end

        @request.record_timeline!(
          from_status: old_status,
          to_status: @new_status,
          actor: @actor,
          metadata: @metadata
        )
      end

      deliver_notifications(@request, old_status)

      Result.success(@request)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    def valid_transition?(from, to)
      VALID_TRANSITIONS.fetch(from, []).include?(to)
    end

    def deliver_notifications(request, old_status)
      adopter = request.adopter
      pet = request.pet
      party_name = request.responsible_party_name

      kind = "request_#{request.status}".to_sym
      title_key = "notifications.titles.#{kind}"
      body_key = "notifications.bodies.#{kind}"

      notification_title = I18n.t(title_key, pet_name: pet.name, shelter_name: party_name.to_s)
      notification_body = I18n.t(body_key, pet_name: pet.name, shelter_name: party_name.to_s)

      result = Notifications::Deliver.call(
        recipient: adopter,
        actor: @actor,
        kind: kind,
        notifiable: request,
        title: notification_title,
        body: notification_body,
        action_url: Rails.application.routes.url_helpers.adoption_request_path(id: request.id, locale: I18n.locale),
        metadata: { pet_name: pet.name, shelter_name: party_name.to_s }
      )

      Rails.logger.warn("Notification delivery failed for request #{request.id}: #{result.errors}") if result.failure?
    end
  end
end

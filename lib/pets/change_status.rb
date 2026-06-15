module Pets
  class ChangeStatus < ApplicationService
    VALID_TRANSITIONS = {
      "available"      => %w[on_hold adopted not_available removed].freeze,
      "on_hold"        => %w[available adopted not_available removed].freeze,
      "adopted"        => %w[available removed].freeze,
      "not_available"  => %w[available removed].freeze,
      "removed"        => %w[].freeze
    }.freeze

    def initialize(pet:, new_status:, adopted_at: nil)
      @pet         = pet
      @new_status  = new_status
      @adopted_at  = adopted_at || Time.current
    end

    def call
      old_status = @pet.status

      return Result.failure(
        I18n.t("pets.errors.invalid_transition", from: old_status, to: @new_status)
      ) unless valid_transition?(old_status, @new_status)

      ActiveRecord::Base.transaction do
        @pet.adopted_at = @adopted_at if @new_status == "adopted"
        @pet.status = @new_status
        @pet.save!
      end

      Result.success(@pet)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    def valid_transition?(from, to)
      VALID_TRANSITIONS.fetch(from, []).include?(to)
    end
  end
end

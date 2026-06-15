module Pets
  class BulkUpdate < ApplicationService
    VALID_STATUSES = %w[available on_hold adopted not_available].freeze

    def initialize(shelter:, pet_ids:, new_status:)
      @shelter     = shelter
      @pet_ids     = Array(pet_ids)
      @new_status  = new_status
    end

    def call
      return Result.failure(I18n.t("pets.errors.bulk.no_ids"))         if @pet_ids.empty?
      return Result.failure(I18n.t("pets.errors.bulk.invalid_status")) unless VALID_STATUSES.include?(@new_status)

      pets = @shelter.pets.undiscarded.where(id: @pet_ids)
      return Result.failure(I18n.t("pets.errors.bulk.not_found")) if pets.empty?

      now = Time.current
      update_attrs = { status: @new_status }
      update_attrs[:adopted_at] = now if @new_status == "adopted"

      updated = pets.update_all(update_attrs)
      Result.success(updated_count: updated)
    end
  end
end

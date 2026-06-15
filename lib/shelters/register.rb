module Shelters
  class Register < ApplicationService
    def initialize(user:, shelter_params:)
      @user = user
      @shelter_params = shelter_params
    end

    def call
      return Result.failure(I18n.t("errors.register_shelter.unverified")) unless @user.verified?
      return Result.failure(I18n.t("errors.register_shelter.has_shelter")) if @user.shelter_id.present?

      shelter = Shelter.new(@shelter_params)

      ActiveRecord::Base.transaction do
        shelter.save!
        @user.update!(shelter: shelter, role: "shelter_admin")
      end

      Result.success(shelter)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

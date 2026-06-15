module Shelters
  class UpdateProfile < ApplicationService
    def initialize(shelter:, user:, params:)
      @shelter = shelter
      @user = user
      @params = params
    end

    def call
      return Result.failure(I18n.t("errors.update_profile.not_admin")) unless @user.shelter_admin?
      return Result.failure(I18n.t("errors.update_profile.wrong_shelter")) unless @user.shelter_id == @shelter.id

      @shelter.update!(@params)
      Result.success(@shelter)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

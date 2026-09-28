module Locations
  class Delete < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      # The consent decision row stays as a historical record (REQ-48-4).
      @user.user_location&.destroy
      Result.success
    end

    private

    attr_reader :user
  end
end

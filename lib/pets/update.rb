module Pets
  class Update < ApplicationService
    def initialize(pet:, params:)
      @pet    = pet
      @params = params
    end

    def call
      @pet.update!(@params)
      Result.success(@pet)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end

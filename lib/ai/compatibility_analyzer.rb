module Ai
  class CompatibilityAnalyzer < ApplicationService
    def initialize(adopter_profile:, pet_profile:)
      @adopter_profile = adopter_profile
      @pet_profile = pet_profile
      super()
    end

    def call
      raise NotImplementedError
    end

    private

    attr_reader :adopter_profile, :pet_profile
  end
end

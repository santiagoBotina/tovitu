module Ai
  class GenerateLifePreview < ApplicationService
    def initialize(household_info:, housing_info:, lifestyle_info:)
      @household_info = household_info
      @housing_info = housing_info
      @lifestyle_info = lifestyle_info
      super()
    end

    def call
      raise NotImplementedError
    end

    private

    attr_reader :household_info, :housing_info, :lifestyle_info
  end
end

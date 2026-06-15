module Shelters
  class DirectorySearch < ApplicationQuery
    def initialize(params: {})
      @city = params[:city]
      @state = params[:state]
      @species = params[:species]
    end

    def call
      scope = Shelter.active.undiscarded

      scope = scope.where("city ILIKE ?", "%#{@city}%") if @city.present?
      scope = scope.where(state: @state.upcase) if @state.present?
      scope = scope.where("species_served @> ?", [ @species ].to_json) if @species.present?

      scope.order(:name)
    end
  end
end

module AdoptionApplications
  class StatusController < ApplicationController
    def show
      @application = AdoptionApplication.find_by!(token: params[:token])
      authorize @application, :show?
    end
  end
end

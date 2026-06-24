module AdoptionApplications
  class StatusController < ApplicationController
    skip_before_action :require_authentication

    def show
      @application = AdoptionApplication.find_by!(token: params[:token])
      authorize @application, :show?
    end
  end
end

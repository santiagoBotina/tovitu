module Authentication
  class SessionsController < ApplicationController
    before_action :require_no_authentication, only: [ :new_adopter, :new_shelter, :create ]

    def new_adopter
      @role = "adopter"
    end

    def new_shelter
      @role = "shelter"
    end

    def create
      result = Authentication::AuthenticateUser.call(
        email: params[:session][:email],
        password: params[:session][:password],
        role: params[:session][:role],
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      if result.success?
        session[:user_id] = result.data[:id]
        redirect_to after_sign_in_path, notice: t("flash.sessions.create.success")
      else
        flash.now[:alert] = Array(result.errors).join(", ")
        if params[:session][:role] == "shelter"
          render :new_shelter, status: :unprocessable_entity
        else
          render :new_adopter, status: :unprocessable_entity
        end
      end
    end

    def destroy
      reset_session
      redirect_to root_path, notice: t("flash.sessions.destroy.success")
    end
  end
end

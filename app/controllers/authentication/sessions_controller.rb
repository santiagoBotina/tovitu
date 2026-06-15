module Authentication
  class SessionsController < ApplicationController
    before_action :require_no_authentication, only: [ :new, :create ]

    def new
    end

    def create
      result = Authentication::AuthenticateUser.call(
        email: params[:session][:email],
        password: params[:session][:password],
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      if result.success?
        session[:user_id] = result.data[:id]
        redirect_to root_path, notice: t("flash.sessions.create.success")
      else
        flash.now[:alert] = Array(result.errors).join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to new_session_path, notice: t("flash.sessions.destroy.success")
    end
  end
end

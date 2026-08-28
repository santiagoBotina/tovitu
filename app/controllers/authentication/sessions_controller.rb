module Authentication
  class SessionsController < ApplicationController
    before_action :require_no_authentication, only: [ :new, :new_individual, :new_adopter, :new_shelter, :create ]

    def new
      @role = params[:role] || "individual"
      clear_stale_auth_redirect
    end

    def new_individual
      @role = "individual"
      clear_stale_auth_redirect
      render :new
    end

    def new_adopter
      @role = "individual"
      redirect_to login_individual_path, status: :moved_permanently
    end

    def new_shelter
      @role = "shelter"
      clear_stale_auth_redirect
      render :new
    end

    def create
      role_param = params[:session][:role]
      normalized_role = role_param == "adopter" ? "individual" : role_param

      result = Authentication::AuthenticateUser.call(
        email: params[:session][:email],
        password: params[:session][:password],
        role: normalized_role,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      if result.success?
        session[:user_id] = result.data[:id]
        redirect_to after_sign_in_path, notice: t("flash.sessions.create.success")
      else
        flash.now[:alert] = Array(result.errors).join(", ")
        @role = normalized_role || "individual"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to root_path, notice: t("flash.sessions.destroy.success"), status: :see_other
    end

    private

    # A return path is only meaningful when the visitor was redirected here by
    # require_authentication (which sets a flash alert). If they reached login
    # directly (e.g. via the navbar), drop any stale path so a navbar-initiated
    # login never surprises them with an unexpected redirect afterwards.
    def clear_stale_auth_redirect
      return if flash[:alert].present?

      session.delete(:return_to)
      session.delete(:auth_intent)
    end
  end
end

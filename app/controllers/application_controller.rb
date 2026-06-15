class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern

  stale_when_importmap_changes

  helper_method :current_user, :signed_in?

  rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique
  rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

  before_action :set_locale

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    return {} if I18n.locale == I18n.default_locale
    { locale: I18n.locale }
  end

  def current_user
    @current_user ||= User.undiscarded.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in?
    current_user.present?
  end

  def require_authentication(role: nil)
    unless signed_in?
      store_location
      redirect_to root_path, alert: t("flash.sessions.require_authentication") and return
    end

    if role.present?
      case role.to_s
      when "adopter"
        unless current_user.adopter?
          redirect_to root_path, alert: t("flash.unauthorized") and return
        end
      when "shelter"
        unless current_user.shelter_user?
          redirect_to root_path, alert: t("flash.unauthorized") and return
        end
      end
    end
  end

  def require_no_authentication
    if signed_in?
      redirect_to after_sign_in_path, notice: t("flash.sessions.require_no_authentication")
    end
  end

  def require_onboarding_complete
    if signed_in? && !current_user.onboarding_completed?
      return if params[:from_profile] == "true"

      destination = Onboarding::DetermineDestination.call(user: current_user)
      redirect_to destination, alert: t("flash.onboarding.incomplete")
    end
  end

  def after_sign_in_path
    if current_user.adopter?
      if current_user.onboarding_completed?
        pets_path
      else
        onboarding_adopter_questions_path
      end
    elsif current_user.shelter_user?
      if current_user.onboarding_completed?
        if current_user.shelter_id.present?
          shelter_dashboard_path(shelter_id: current_user.shelter_id)
        else
          new_shelter_path
        end
      else
        onboarding_shelter_questions_path
      end
    else
      root_path
    end
  end

  def store_location
    session[:return_to] = request.fullpath unless request.xhr?
  end

  def handle_unauthorized
    redirect_to root_path, alert: t("flash.unauthorized")
  end

  def handle_record_not_unique(exception)
    message = if exception.message.include?("index_users_on_email")
      t("flash.record_not_unique.email")
    else
      t("flash.record_not_unique.generic")
    end

    redirect_to request.referer || root_path, alert: message
  end
end

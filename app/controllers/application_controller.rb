class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
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

  def require_authentication
    unless signed_in?
      redirect_to new_session_path, alert: t("flash.sessions.require_authentication")
    end
  end

  def require_no_authentication
    if signed_in?
      redirect_to root_path, notice: t("flash.sessions.require_no_authentication")
    end
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

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?

  rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique

  private

  def current_user
    @current_user ||= User.undiscarded.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in?
    current_user.present?
  end

  def require_authentication
    unless signed_in?
      redirect_to new_session_path, alert: "Please log in to continue."
    end
  end

  def require_no_authentication
    if signed_in?
      redirect_to root_path, notice: "You are already logged in."
    end
  end

  def handle_record_not_unique(exception)
    message = if exception.message.include?("index_users_on_email")
      "This email is already registered. Please try logging in or use a different email."
    else
      "A database constraint was violated. Please try again."
    end

    redirect_to request.referer || root_path, alert: message
  end
end

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern

  stale_when_importmap_changes

  helper_method :current_user, :signed_in?, :auth_flow?, :auth_intent_pet

  rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique
  rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

  before_action :set_locale

  private

  LOCALE_WHITELIST = %w[en es].freeze

  def set_locale
    I18n.locale = params[:locale]&.then { |l| LOCALE_WHITELIST.include?(l) ? l.to_sym : nil } || I18n.default_locale
  end

  def default_url_options
    locale = if signed_in? && current_user.locale.present?
      current_user.locale.to_sym
    else
      I18n.locale
    end
    { locale: locale }
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
      store_auth_intent
      redirect_to new_session_path, alert: t("flash.sessions.require_authentication") and return
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
    if session[:return_to].present?
      if current_user.onboarding_completed?
        return consume_return_to
      end

      # Onboarding is still required: keep the return path in the session so
      # the onboarding completion step can send the user back to where they
      # were heading (e.g. the adoption application they started).
      return Onboarding::DetermineDestination.call(user: current_user)
    end

    if current_user.adopter?
      if current_user.onboarding_completed?
        user_dashboard_path
      else
        onboarding_individual_questions_path
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

  # True while rendering the standalone authentication flow (Login, Sign Up,
  # password reset, verification). These screens get a minimal navbar with a
  # single way back home instead of the full app navigation.
  def auth_flow?
    controller_path.start_with?("authentication/") && controller_path != "authentication/profiles"
  end

  # The pet a signed-out visitor was applying for when they were asked to log
  # in. Used by the login screen to show a friendly "continue your application"
  # reason instead of a bare login wall.
  def auth_intent_pet
    intent = session[:auth_intent]
    return nil unless intent.is_a?(Hash) && intent["type"] == "adoption_request"
    Pet.undiscarded.find_by(id: intent["pet_id"])
  end

  def store_location
    session[:return_to] = request.fullpath unless request.xhr?
  end

  # Remembers why a signed-out visitor was sent to login, so the login screen
  # can explain the redirect and the post-auth flow can return them to it.
  def store_auth_intent
    return unless controller_path == "adoption_requests" && action_name.in?(%w[new create])
    session[:auth_intent] = { "type" => "adoption_request", "pet_id" => params[:pet_id] }
  end

  # Reads and clears the stored return path. Only internal paths are honored
  # (defense against open redirects); nil is returned for anything else.
  def consume_return_to
    path = session.delete(:return_to)
    return nil unless path.is_a?(String) && path.start_with?("/") && !path.start_with?("//")
    path
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

  # Computes the "milestone unlocked" message when the given milestone
  # transitions from locked to unlocked for the user. Callers pass `was_done:`
  # — whether the milestone was already complete before the action (e.g. the
  # user already had a saved pet). This keeps the feedback honest: it only
  # fires on the first time the milestone is reached.
  #
  # Returns the milestone message (or nil) so callers can prefer it over a
  # generic action notice. Callers are responsible for surfacing it: via
  # `redirect_to ... notice:`, or appended inline as a turbo_stream toast.
  # This helper deliberately does NOT write to `flash` so the message is never
  # shown twice (once as a session flash and once as an inline toast).
  def milestone_unlocked_message(user, milestone_key, was_done:)
    return nil if was_done

    journey = Gamification::Journey.new(user)
    milestone = journey.milestones.find { |m| m[:key] == milestone_key }
    return nil unless milestone && milestone[:done]

    t("gamification.milestone_unlocked.#{milestone_key}")
  end
end

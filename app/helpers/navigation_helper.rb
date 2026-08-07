module NavigationHelper
  # Strip the locale prefix from the request path for matching sidebar links.
  # All routes are nested under scope ":locale", so paths look like /en/pets, /es/shelters, etc.
  def locale_aware_path
    @locale_aware_path ||= request.path.sub(/\A\/(en|es)/, "").presence || "/"
  end

  # Resolve a "back" link destination. When the page was reached with a
  # `back_to` query param (e.g. arriving at a pet profile from an adoption
  # request detail), return that path so the back button leads the user back
  # to where they came from instead of a hardcoded listing.
  #
  # Falls back to +fallback_path+ when `back_to` is absent, malformed, or
  # points outside the app — never renders an external URL.
  def safe_back_path(fallback_path)
    back_to = params[:back_to].to_s
    return fallback_path if back_to.blank?

    # Only same-origin, internal absolute paths. Reject protocol-relative
    # (//host) and scheme-prefixed (https://host) URLs, plus backslash tricks
    # that browsers normalize into protocol-relative URLs.
    return fallback_path unless back_to.start_with?("/")
    return fallback_path if back_to.start_with?("//") || back_to.include?("\\")

    path = back_to.split("?").first
    Rails.application.routes.recognize_path(path, method: :get)
    back_to
  rescue ActionController::RoutingError, URI::InvalidURIError, ArgumentError
    fallback_path
  end

  def dashboard_active?(user)
    if user.adopter?
      current_page?(user_dashboard_path) || locale_aware_path.start_with?("/dashboard")
    elsif user.shelter_user?
      locale_aware_path.start_with?("/dashboard") ||
        locale_aware_path.match?(%r{^/shelters/\d+/dashboard($|/)}) ||
        current_page?(root_path)
    else
      false
    end
  end

  def path_active?(path_segment)
    locale_aware_path.start_with?(path_segment)
  end

  def shelters_active?(user)
    return false if user.adopter?

    path_active?("/shelters") && !locale_aware_path.start_with?("/shelters/dashboard")
  end

  def shelter_sidebar_link_active?(path)
    # Use locale-aware comparison for shelter-scoped routes
    locale_aware_path == path || current_page?(path)
  end
end

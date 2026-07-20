module NavigationHelper
  # Strip the locale prefix from the request path for matching sidebar links.
  # All routes are nested under scope ":locale", so paths look like /en/pets, /es/shelters, etc.
  def locale_aware_path
    @locale_aware_path ||= request.path.sub(/\A\/(en|es)/, "").presence || "/"
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

module NavigationHelper
  def dashboard_active?(user)
    if user.adopter?
      current_page?(user_dashboard_path) || request.path.start_with?("/dashboard")
    elsif user.shelter_user?
      request.path.include?("/dashboard") || current_page?(root_path)
    else
      false
    end
  end

  def shelters_active?(user)
    return false if user.adopter?

    request.path.start_with?("/shelters") && !request.path.include?("/dashboard")
  end

  def shelter_sidebar_link_active?(path)
    current_page?(path) || request.path == path
  end
end

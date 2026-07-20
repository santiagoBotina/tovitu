class NotificationPreferencePolicy < ApplicationPolicy
  def edit?
    user.present?
  end

  def update?
    edit?
  end
end

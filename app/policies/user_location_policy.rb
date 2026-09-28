class UserLocationPolicy < ApplicationPolicy
  # The owning adopter manages their own location (view/modify/delete). Shelter
  # staff never manage a UserLocation directly — they only read the city-level
  # display value in shelter-facing views (REQ-48-5 privacy boundary).
  def create?
    user.present? && user.individual? && owner?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  private

  def owner?
    record.user_id == user.id
  end
end

class ShelterProfilePolicy < ApplicationPolicy
  def show?
    user == record.user || shelter_admin_or_staff?
  end

  def update?
    user == record.user || shelter_admin?
  end

  def edit?
    update?
  end

  def complete?
    user == record.user
  end

  private

  def shelter_admin?
    user.shelter_admin? && record.shelter.present? && user.shelter_id == record.shelter_id
  end

  def shelter_admin_or_staff?
    shelter_admin? || (user.shelter_staff? && record.shelter.present? && user.shelter_id == record.shelter_id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.shelter_admin? || user.admin?
        scope.where(shelter_id: user.shelter_id)
      elsif user.adopter?
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end

class ShelterProfilePolicy < ApplicationPolicy
  def show?
    user == record.user || shelter_member?
  end

  def update?
    user == record.user || shelter_owner?
  end

  def edit?
    update?
  end

  def complete?
    user == record.user
  end

  private

  def shelter_owner?
    user.shelter_owner? && record.shelter.present? && user.shelter_id == record.shelter_id
  end

  def shelter_member?
    user.shelter_member? && record.shelter.present? && user.shelter_id == record.shelter_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.shelter_owner? || user.admin?
        scope.where(shelter_id: user.shelter_id)
      elsif user.adopter?
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end

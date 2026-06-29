class AdoptionRequestPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return record.adopter_id == user.id if user.adopter?
    return user.shelter_id == record.shelter_id if user.shelter_user?
    false
  end

  def new?
    create?
  end

  def create?
    user.present? && user.adopter? && user.onboarding_completed?
  end

  def update?
    user.present? && user.shelter_user? && user.shelter_id == record.shelter_id
  end

  def manage?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.adopter?
        scope.where(adopter_id: user.id)
      elsif user.shelter_user? && user.shelter_id.present?
        scope.where(shelter_id: user.shelter_id)
      else
        scope.none
      end
    end
  end
end

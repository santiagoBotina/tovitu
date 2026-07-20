class AdoptionRequestPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return record.adopter_id == user.id if user.individual?
    return user.shelter_id == record.shelter_id if user.shelter_user?
    false
  end

  def new?
    create?
  end

  def create?
    user.present? && user.individual? && user.onboarding_completed?
  end

  def update?
    return true if user.present? && user.shelter_user? && user.shelter_id == record.shelter_id
    return true if user.present? && user.individual? && record.pet.publisher_id == user.id
    false
  end

  def withdraw?
    return true if user.present? && user.individual? && record.adopter_id == user.id && record.withdrawable?
    false
  end

  def manage?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.individual?
        scope.where(adopter_id: user.id)
      elsif user.shelter_user? && user.shelter_id.present?
        scope.where(shelter_id: user.shelter_id)
      else
        scope.none
      end
    end
  end
end

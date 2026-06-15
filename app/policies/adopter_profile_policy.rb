class AdopterProfilePolicy < ApplicationPolicy
  def show?
    user == record.user
  end

  def update?
    user == record.user
  end

  def edit?
    update?
  end

  def complete?
    user == record.user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end

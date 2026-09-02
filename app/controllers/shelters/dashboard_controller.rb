module Shelters
  class DashboardController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def show
      authorize @shelter, :dashboard?

      # Track welcome overlay dismissal
      if params[:welcome_dismissed] == "true"
        session[:welcome_overlay_dismissed] = true
      end

      @total_pets = @shelter.pets.undiscarded.count
      @adoptable_pets = @shelter.pets.undiscarded.where(status: :available).count
      @pending_requests = @shelter.adoption_requests.where(status: :pending).count
      @in_review_requests = @shelter.adoption_requests.where(status: :in_validation).count
      @active_adoptions = @shelter.adoption_requests.where(status: :accepted).count
      @total_requests_count = @shelter.adoption_requests.count

      @recent_activity = @shelter.adoption_requests
                           .includes(:pet, :adopter)
                           .order(updated_at: :desc)
                           .limit(5)

      base = @shelter.pets.undiscarded.where(status: %w[available on_hold])
      # left_joins on both sides keeps the .or structurally compatible; distinct
      # guards against a pet with multiple photos matching more than once.
      @pets_needing_attention = base.left_joins(:photos_attachments)
                                   .where("description IS NULL OR description = ''")
                                   .or(base.left_joins(:photos_attachments).where(active_storage_attachments: { id: nil }))
                                   .distinct
                                   .includes(photos_attachments: :blob)
                                   .order(created_at: :desc)
                                   .limit(5)
                                   .map do |pet|
                                     missing = []
                                     missing << :photo if pet.photos.empty?
                                     missing << :description if pet.description.blank?
                                     { pet: pet, missing: missing }
                                   end

      @staff_count = @shelter.users.undiscarded.count
      @staff_members = @shelter.users.undiscarded.limit(5)
    end

    # Permanently hides a completed onboarding checklist for this shelter.
    # Admin-only (hides the checklist for the whole team) and guarded by
    # Shelters::DismissChecklist: only complete checklists dismiss.
    def dismiss_checklist
      authorize @shelter, :manage?

      result = Shelters::DismissChecklist.call(shelter: @shelter)
      if result.success?
        redirect_to shelter_dashboard_path(@shelter), notice: t("shelters.dashboard.show.onboarding.dismissed_confirmation")
      else
        redirect_to shelter_dashboard_path(@shelter), alert: Array(result.errors).join(", ")
      end
    end

    # Brings a dismissed onboarding checklist back onto the dashboard.
    # Admin-only: restoring also changes the checklist state for the whole team.
    def restore_checklist
      authorize @shelter, :manage?

      Shelters::RestoreChecklist.call(shelter: @shelter)
      redirect_to shelter_dashboard_path(@shelter), notice: t("shelters.dashboard.show.onboarding.restored_confirmation")
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end
  end
end

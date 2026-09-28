module Shelters
  class PoliciesController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def show
      authorize @shelter, :policies_edit?
      load_evaluation
    end

    def edit
      authorize @shelter, :policies_edit?
    end

    def update
      authorize @shelter, :policies_update?

      @shelter.update!(adoption_policies: policy_params)

      redirect_to shelter_policies_path(shelter_id: @shelter), notice: t("flash.policies.update.success")
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_content
    end

    # Add natural-language policies (one per line) and translate them into
    # proposed rules (REQ-49-4, REQ-49-11). Provider failure is graceful: the
    # raw text is kept, the policy is marked failed, and a retry is surfaced.
    def add_policy
      authorize @shelter, :manage_policies?

      statements = policy_statements
      if statements.empty?
        return redirect_to shelter_policies_path(shelter_id: @shelter),
                           alert: t("adoptions.evaluation.errors.policy_blank")
      end

      policies = statements.filter_map do |line|
        Adoptions::StoreEvaluationPolicy.call(shelter: @shelter, content: line).data
      end

      result = Adoptions::TranslatePolicies.call(shelter: @shelter, policies: policies)

      if result.success?
        redirect_to shelter_policies_path(shelter_id: @shelter),
                    notice: t("adoptions.evaluation.flash.policies_translated")
      else
        mark_failed(policies)
        redirect_to shelter_policies_path(shelter_id: @shelter),
                    alert: t("adoptions.evaluation.flash.policies_failed")
      end
    end

    # Re-run translation for policies that are still draft or failed.
    def translate
      authorize @shelter, :manage_policies?

      policies = @shelter.evaluation_policies.actionable.to_a
      result = Adoptions::TranslatePolicies.call(shelter: @shelter, policies: policies)

      if result.success?
        redirect_to shelter_policies_path(shelter_id: @shelter),
                    notice: t("adoptions.evaluation.flash.policies_translated")
      else
        mark_failed(policies)
        redirect_to shelter_policies_path(shelter_id: @shelter),
                    alert: t("adoptions.evaluation.flash.policies_failed")
      end
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end

    def load_evaluation
      @evaluation_policies = @shelter.evaluation_policies.includes(:rules).order(:id)
      @evaluation_system_rules = system_rules_config
    end

    def system_rules_config
      Rails.application.config_for(:evaluation).dig(:system_rules) || {}
    end

    def policy_statements
      params[:policy_content].to_s.split("\n").map(&:strip).reject(&:blank?)
    end

    def mark_failed(policies)
      policies.each do |policy|
        policy.update_columns(status: "failed") unless policy.translated?
      end
    end

    def policy_params
      params.require(:shelter).permit(
        adoption_policies: %i[
          adoption_fee fee_description minimum_age
          home_visit_required fenced_yard_required
          vet_reference_required other_requirements
        ]
      ).fetch(:adoption_policies, {})
    end
  end
end

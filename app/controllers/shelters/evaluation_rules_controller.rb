module Shelters
  # Management of the translated evaluation rules a shelter has reviewed
  # (REQ-49-11): enable/disable, edit severity/parameters, or remove a rule.
  # Owner/administrator only (ShelterPolicy#manage_policies?).
  class EvaluationRulesController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def update
      authorize @shelter, :manage_policies?

      rule = @shelter.evaluation_rules.find(params[:id])
      rule.assign_attributes(rule_params(rule))
      rule.save!

      redirect_to shelter_policies_path(shelter_id: @shelter),
                  notice: t("flash.policies.update.success")
    rescue ActiveRecord::RecordNotFound
      redirect_to shelter_policies_path(shelter_id: @shelter),
                  alert: t("adoptions.evaluation.errors.not_authorized")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to shelter_policies_path(shelter_id: @shelter),
                  alert: e.record.errors.full_messages.join(", ")
    end

    def destroy
      authorize @shelter, :manage_policies?

      rule = @shelter.evaluation_rules.find(params[:id])
      rule.destroy!

      redirect_to shelter_policies_path(shelter_id: @shelter),
                  notice: t("flash.policies.update.success")
    rescue ActiveRecord::RecordNotFound
      redirect_to shelter_policies_path(shelter_id: @shelter),
                  alert: t("adoptions.evaluation.errors.not_authorized")
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end

    def rule_params(rule)
      raw = params.require(:rule).permit(:severity, :enabled, params: {})
      attributes = {}
      attributes[:severity] = raw[:severity] if raw[:severity].present?
      attributes[:enabled] = raw[:enabled] == "true" if raw.key?(:enabled)
      if raw[:params].present?
        attributes[:params] = Adoptions::Evaluation::RuleCatalog.normalize_params(rule.rule_type, raw[:params])
      end
      attributes
    end
  end
end

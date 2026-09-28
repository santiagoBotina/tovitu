class RenameExplanationToReasonOnShelterEvaluationPolicies < ActiveRecord::Migration[8.1]
  def change
    rename_column :shelter_evaluation_policies, :explanation, :reason
  end
end

class CreateShelterEvaluationPolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :shelter_evaluation_policies do |t|
      t.references :shelter, null: false, foreign_key: true
      t.text :content, null: false
      t.string :status, null: false, default: "draft"
      t.text :explanation

      t.timestamps
    end

    create_table :shelter_evaluation_rules do |t|
      t.references :policy, null: false, foreign_key: { to_table: :shelter_evaluation_policies }
      t.string :rule_type, null: false
      t.jsonb :params, default: {}
      t.string :severity, null: false, default: "yellow"
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end
  end
end

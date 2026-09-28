class CreateAdoptionRequestEvaluations < ActiveRecord::Migration[8.1]
  def change
    create_table :adoption_request_evaluations do |t|
      t.references :adoption_request, null: false, foreign_key: true, index: { unique: true }
      t.string :verdict, null: false
      t.jsonb :summary, default: {}
      t.jsonb :rules, default: []
      t.integer :version, null: false, default: 1
      t.datetime :evaluated_at, null: false

      t.timestamps
    end
  end
end

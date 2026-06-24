class CreateAiDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_documents do |t|
      t.references :shelter, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.string :source_type, null: false
      t.string :status, default: "processing", null: false
      t.text :error_message
      t.timestamps
    end

    add_index :ai_documents, [:shelter_id, :status]
  end
end

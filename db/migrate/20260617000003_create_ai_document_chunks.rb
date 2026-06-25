class CreateAiDocumentChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_document_chunks do |t|
      t.references :ai_document, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :chunk_index, null: false
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE ai_document_chunks ADD COLUMN embedding vector(1536);
    SQL
    add_index :ai_document_chunks, [ :ai_document_id, :chunk_index ], unique: true
  end
end

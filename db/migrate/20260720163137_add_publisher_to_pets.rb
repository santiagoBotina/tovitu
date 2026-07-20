class AddPublisherToPets < ActiveRecord::Migration[8.0]
  def change
    change_column_null :pets, :shelter_id, true

    add_reference :pets, :publisher, foreign_key: { to_table: :users }, null: true
  end
end

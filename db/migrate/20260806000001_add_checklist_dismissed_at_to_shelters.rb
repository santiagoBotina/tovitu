class AddChecklistDismissedAtToShelters < ActiveRecord::Migration[8.1]
  def change
    add_column :shelters, :checklist_dismissed_at, :datetime
  end
end

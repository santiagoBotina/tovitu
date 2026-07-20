class AddAdoptionRequestFields < ActiveRecord::Migration[8.1]
  def change
    add_column :adoption_requests, :additional_answers, :jsonb, default: {}
    add_column :adoption_requests, :withdrawn_at, :datetime
  end
end

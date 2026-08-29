class AddRecommendationToPets < ActiveRecord::Migration[8.1]
  def change
    add_column :pets, :recommendation, :text
  end
end

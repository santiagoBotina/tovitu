class AddEvaluationFieldsToIndividualProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :individual_profiles, :date_of_birth, :date
    add_column :individual_profiles, :home_environment, :string
    add_column :individual_profiles, :other_pets, :string
  end
end

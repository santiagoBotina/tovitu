class AddNewRolesToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :onboarding_completed_at, :datetime
    add_column :users, :onboarding_step, :integer, default: 0, null: false

    change_column_default :users, :role, from: "staff", to: "adopter"

    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT valid_role
      CHECK (role IN ('adopter', 'shelter_admin', 'shelter_staff', 'admin', 'staff'))
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE users DROP CONSTRAINT valid_role
    SQL

    change_column_default :users, :role, from: "adopter", to: "staff"
    remove_column :users, :onboarding_step
    remove_column :users, :onboarding_completed_at
  end
end

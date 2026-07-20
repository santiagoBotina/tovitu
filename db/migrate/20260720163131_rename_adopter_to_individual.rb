class RenameAdopterToIndividual < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      ALTER TABLE users DROP CONSTRAINT IF EXISTS valid_role;
    SQL

    execute <<-SQL
      UPDATE users SET role = 'individual' WHERE role = 'adopter'
    SQL

    change_column_default :users, :role, from: "adopter", to: "individual"

    execute <<-SQL
      ALTER TABLE users ADD CONSTRAINT valid_role
        CHECK (role IN ('individual', 'shelter_admin', 'shelter_staff', 'admin', 'staff'))
    SQL

    rename_table :adopter_profiles, :individual_profiles
  end

  def down
    rename_table :individual_profiles, :adopter_profiles

    execute <<-SQL
      ALTER TABLE users DROP CONSTRAINT IF EXISTS valid_role;
    SQL

    execute <<-SQL
      ALTER TABLE users ADD CONSTRAINT valid_role
        CHECK (role IN ('adopter', 'shelter_admin', 'shelter_staff', 'admin', 'staff'))
    SQL

    execute <<-SQL
      UPDATE users SET role = 'adopter' WHERE role = 'individual'
    SQL

    change_column_default :users, :role, from: "individual", to: "adopter"
  end
end

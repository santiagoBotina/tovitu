class AddShelterRolesAndInvitationRoles < ActiveRecord::Migration[8.1]
  SHELTER_ROLES = %w[owner administrator staff_member].freeze

  def up
    add_column :users, :shelter_role, :string

    execute <<~SQL.squish
      ALTER TABLE users
      ADD CONSTRAINT valid_shelter_role
      CHECK (shelter_role IS NULL OR shelter_role IN ('owner', 'administrator', 'staff_member'))
    SQL

    execute <<~SQL.squish
      UPDATE users SET shelter_role = 'owner'
      WHERE shelter_id IS NOT NULL AND role = 'shelter_admin'
    SQL

    execute <<~SQL.squish
      UPDATE users SET shelter_role = 'staff_member'
      WHERE shelter_id IS NOT NULL AND role = 'shelter_staff'
    SQL

    add_column :invitations, :role, :string
    add_column :invitations, :cancelled_at, :datetime

    execute <<~SQL.squish
      UPDATE invitations SET role = 'staff_member' WHERE role IS NULL
    SQL

    change_column_null :invitations, :role, false

    execute <<~SQL.squish
      ALTER TABLE invitations
      ADD CONSTRAINT valid_invitation_role
      CHECK (role IN ('owner', 'administrator', 'staff_member'))
    SQL
  end

  def down
    execute "ALTER TABLE invitations DROP CONSTRAINT valid_invitation_role"
    remove_column :invitations, :cancelled_at
    remove_column :invitations, :role

    execute "ALTER TABLE users DROP CONSTRAINT valid_shelter_role"
    remove_column :users, :shelter_role
  end
end

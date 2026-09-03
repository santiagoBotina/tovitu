class RestrictInvitationRoleToInvitable < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE invitations DROP CONSTRAINT valid_invitation_role"

    execute <<~SQL.squish
      ALTER TABLE invitations
      ADD CONSTRAINT valid_invitation_role
      CHECK (role IN ('administrator', 'staff_member'))
    SQL
  end

  def down
    execute "ALTER TABLE invitations DROP CONSTRAINT valid_invitation_role"

    execute <<~SQL.squish
      ALTER TABLE invitations
      ADD CONSTRAINT valid_invitation_role
      CHECK (role IN ('owner', 'administrator', 'staff_member'))
    SQL
  end
end

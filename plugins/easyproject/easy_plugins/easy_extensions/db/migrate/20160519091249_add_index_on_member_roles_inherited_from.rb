class AddIndexOnMemberRolesInheritedFrom < ActiveRecord::Migration[4.2]
  def self.up
    add_index :member_roles, :inherited_from unless index_exists?(:member_roles, :inherited_from)
  end

  def self.down
    remove_index :member_roles, :inherited_from
  end
end

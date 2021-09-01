class AddRoleListToEasyPermissions < ActiveRecord::Migration[4.2]
  def self.up

    add_column :easy_permissions, :role_list, :text, :null => true

  end

  def self.down

    remove_column :easy_permissions, :role_list

  end
end

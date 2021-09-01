class ChangePermissions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_permissions, :permissions, :text, { :null => true }
  end

  def self.down
    remove_column :easy_permissions, :permissions
  end
end

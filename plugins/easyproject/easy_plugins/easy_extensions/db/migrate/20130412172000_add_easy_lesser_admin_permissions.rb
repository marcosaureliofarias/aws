class AddEasyLesserAdminPermissions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :easy_lesser_admin_permissions, :text, { :null => true }
  end

  def self.down
    remove_column :users, :easy_lesser_admin_permissions
  end

end
class AddLimitAssignableUsersToRole < ActiveRecord::Migration[4.2]
  def self.up
    add_column :roles, :limit_assignable_users, :boolean, { :null => false, :default => false }
  end

  def self.down
    remove_column :roles, :limit_assignable_users
  end
end

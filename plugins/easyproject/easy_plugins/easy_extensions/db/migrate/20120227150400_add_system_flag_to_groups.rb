class AddSystemFlagToGroups < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :easy_system_flag, :boolean, { :null => false, :default => false }
  end

  def self.down
    remove_column :users, :easy_system_flag
  end
end

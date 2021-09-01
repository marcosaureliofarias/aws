class AddSelfRegisteredColumnToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :self_registered, :boolean, :default => false
  end

  def self.down
    remove_column :users, :self_registered
  end
end

class AddSuperiorsToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :parent_id, :integer, :default => nil
    add_column :users, :lft, :integer, :default => nil
    add_column :users, :rgt, :integer, :default => nil

    add_index :users, [:lft, :rgt]
  end

  def self.down
    remove_column :users, :parent_id if column_exists?(:users, :parent_id)
    remove_column :users, :lft if column_exists?(:users, :lft)
    remove_column :users, :rgt if column_exists?(:users, :rgt)
  end
end

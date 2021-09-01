class AddGroupsOpenedToEasyQuery < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_queries, :groups_opened, :boolean, :default => true
  end

  def down
    remove_column :easy_queries, :groups_opened
  end
end

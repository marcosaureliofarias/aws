class AddEasyLevelToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :easy_level, :integer, :null => true
  end

  def self.down
    remove_column :projects, :easy_level
  end
end
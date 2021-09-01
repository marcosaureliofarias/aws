class AddEasyLevelToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :easy_level, :integer, :null => true
  end

  def self.down
    remove_column :issues, :easy_level
  end
end
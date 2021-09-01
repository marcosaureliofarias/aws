class AddSettingsColumnToEasyQuery < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_queries, :settings, :text, :null => true
  end

  def self.down
    remove_column :easy_queries, :settings
  end
end

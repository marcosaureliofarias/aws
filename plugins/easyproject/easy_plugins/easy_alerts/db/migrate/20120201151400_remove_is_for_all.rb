class RemoveIsForAll < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :easy_alerts, :is_for_all
  end

  def self.down
  end
  
end
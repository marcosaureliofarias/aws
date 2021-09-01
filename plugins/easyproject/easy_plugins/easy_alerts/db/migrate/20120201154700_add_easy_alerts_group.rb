class AddEasyAlertsGroup < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :group_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_alerts, :group_id
  end
  
end
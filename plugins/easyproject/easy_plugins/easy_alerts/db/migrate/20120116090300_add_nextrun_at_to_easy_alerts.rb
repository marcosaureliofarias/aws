class AddNextrunAtToEasyAlerts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :nextrun_at, :datetime, {:null => true}
  end

  def self.down
    remove_column :easy_alerts, :nextrun_at
  end
  
end
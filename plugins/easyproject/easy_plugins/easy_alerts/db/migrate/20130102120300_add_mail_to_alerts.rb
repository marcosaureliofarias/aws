class AddMailToAlerts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :mail, :string, {:null => true, :limit => 2048}
  end

  def self.down
    remove_column :easy_alerts, :mail
  end
  
end
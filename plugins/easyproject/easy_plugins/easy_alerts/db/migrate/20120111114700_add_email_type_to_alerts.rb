class AddEmailTypeToAlerts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :email_type, :integer, {:null => false, :default => 1}
  end

  def self.down
  end
  
end
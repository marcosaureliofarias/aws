class AddIsForAllToAlerts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :is_for_all, :boolean, {:null => false, :default => false}
  end

  def self.down
  end
end
class AddIsDefaultToAlertTypes < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alert_types, :is_default, :boolean, {:null => false, :default => false}
  end

  def self.down
    remove_column :easy_alert_types, :is_default
  end
end
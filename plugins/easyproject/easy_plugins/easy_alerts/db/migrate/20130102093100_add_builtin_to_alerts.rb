class AddBuiltinToAlerts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :builtin, :integer, {:null => false, :default => 0}
  end

  def self.down
    remove_column :easy_alerts, :builtin
  end
  
end
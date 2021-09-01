class AddNameToAlerts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :name, :string,  {:null => false, :default => ""}
  end

  def self.down
    remove_column :easy_alerts, :name
  end
end

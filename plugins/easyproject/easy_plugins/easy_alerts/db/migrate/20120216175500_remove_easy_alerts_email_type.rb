class RemoveEasyAlertsEmailType < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :easy_alerts, :email_type
  end

  def self.down
  end
  
end
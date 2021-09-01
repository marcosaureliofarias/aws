class RemoveEasyAlertsUsers < ActiveRecord::Migration[4.2]

  def self.up
    drop_table :easy_alerts_users if table_exists?('easy_alerts_users')
  end

  def self.down
  end

end

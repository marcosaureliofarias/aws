class AddExpiresAtToEasyAlertReports < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alert_reports, :expires_at, :datetime, {:null => true}
  end

  def self.down
    remove_column :easy_alert_reports, :expires_at
  end
  
end
class AddUserIdToAlertReports < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alert_reports, :user_id, :integer, {:null => false}
  end

  def self.down
    remove_column :easy_alert_reports, :user_id
  end
end
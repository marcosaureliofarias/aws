class AddEmailedOn < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alert_reports, :emailed_on, :datetime, {:null => true}
  end

  def self.down
    remove_column :easy_alert_reports, :emailed_on
  end
  
end
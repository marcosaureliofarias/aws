class AddIndexToAlertReports < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_alert_reports, :emailed, :name => 'index_easy_alert_reports_on_emailed' unless index_exists?(:easy_alert_reports, :emailed, :name => 'index_easy_alert_reports_on_emailed')
    add_index :easy_alert_reports, :alert_id, :name => 'index_easy_alert_reports_on_alert_id' unless index_exists?(:easy_alert_reports, :alert_id, :name => 'index_easy_alert_reports_on_alert_id')
    add_index :easy_alert_reports, :user_id, :name => 'index_easy_alert_reports_on_user_id' unless index_exists?(:easy_alert_reports, :user_id, :name => 'index_easy_alert_reports_on_user_id')
    add_index :easy_alert_reports, [:entity_id, :entity_type], :name => 'index_easy_alert_reports_on_entity' unless index_exists?(:easy_alert_reports, [:entity_id, :entity_type], :name => 'index_easy_alert_reports_on_entity')
  end

  def self.down
  end
end
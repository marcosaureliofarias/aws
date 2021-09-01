class RemoveEntityPresenceFromEasyAlertReports < ActiveRecord::Migration[4.2]
  def up
    change_column :easy_alert_reports, :entity_id, :integer, {null: true, default: nil}
    change_column :easy_alert_reports, :entity_type, :string, {null: true, default: nil}
  end

  def down

  end
end

class ChangeDefaultPositionToNullForAlerts < ActiveRecord::Migration[4.2]
  def up
    [:easy_alerts, :easy_alert_types, :easy_alert_rules, :easy_alert_contexts].each do |t|
      change_column t, :position, :integer, { :null => true, :default => nil }
    end
  end

  def down
  end
end

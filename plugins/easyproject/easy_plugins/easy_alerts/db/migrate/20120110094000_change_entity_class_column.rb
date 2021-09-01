class ChangeEntityClassColumn < ActiveRecord::Migration[4.2]

  def self.up
    rename_column :easy_alert_reports, :entity_class, :entity_type
  end

  def self.down
    rename_column :easy_alert_reports, :entity_type, :entity_class
  end
  
end
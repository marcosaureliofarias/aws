class CreateEasyAlertReports < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_alert_reports do |t|
      t.column :alert_id, :integer, :null => false
      t.column :entity_id, :integer, :null => false
      t.column :entity_class, :string, :null => false
      t.column :archived, :boolean, :default => false
      t.column :emailed, :boolean, :default => false
      t.column :created_on, :timestamp
    end
  end

  def self.down
    drop_table :easy_alert_reports
  end
end

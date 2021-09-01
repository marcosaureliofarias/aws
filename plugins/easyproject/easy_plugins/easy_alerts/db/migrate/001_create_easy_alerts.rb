class CreateEasyAlerts < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_alerts do |t|
      t.column :author_id, :integer, :null => false
      t.column :type_id, :integer, :null => false
      t.column :rule_id, :integer, :null => false
      t.column :rule_settings, :text
      t.column :position, :integer, { :null => true, :default => 1 }
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end
  end

  def self.down
    drop_table :easy_alerts
  end
end
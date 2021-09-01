class CreateEasyAlertRules < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_alert_rules do |t|
      t.column :name, :string, { :null => false, :default => '' }
      t.column :context_id, :integer, :null => false
      t.column :class_name, :string, { :null => false, :default => '' }
      t.column :position, :integer, { :null => true, :default => nil }
    end
  end

  def self.down
    drop_table :easy_alert_rules
  end
end

class CreateEasyAlertContexts < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_alert_contexts do |t|
      t.column :name, :string, { :null => false, :default => "" }
      t.column :position, :integer, { :null => true, :default => 1 }
    end

     AlertContext.create :name => "project", :position => 1
     AlertContext.create :name => "issue", :position => 2
     AlertContext.create :name => "milestone", :position => 3
  end

  def self.down
    drop_table :easy_alert_contexts
  end
end

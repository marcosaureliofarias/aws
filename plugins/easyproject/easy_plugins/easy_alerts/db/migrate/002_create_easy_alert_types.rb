class CreateEasyAlertTypes < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_alert_types do |t|
      t.column :name, :string, { :null => false, :default => "" }
      t.column :position, :integer, { :null => true, :default => 1 }
      t.column :color, :string, { :null => false, :default => "" }
      t.column :is_deletable, :boolean, { :null => false, :default => true }
    end

     AlertType.reset_column_information

     AlertType.create :name => "alert", :position => 1, :color => "#FF0000", :is_deletable => false
     AlertType.create :name => "warning", :position => 2, :color => "#FF8C00", :is_deletable => false
     AlertType.create :name => "notice", :position => 3, :color => "#3399CC", :is_deletable => false
  end

  def self.down
    drop_table :easy_alert_types
  end
end

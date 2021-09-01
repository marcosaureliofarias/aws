class CreateEasyMoneyTravelCosts < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_money_travel_costs do |t|
      t.column :easy_external_id, :string, {:null => true, :limit => 255}
      t.column :spent_on, :date, { :null => true }
      t.column :name, :string, { :null => false, :limit => 255 }
      t.column :description, :text, { :null => true }
      t.column :price1, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :entity_id, :integer, { :null => false }
      t.column :project_id, :integer, {:null => true}
      t.column :version_id, :integer, {:null => true}
      t.column :price_per_unit, :decimal, {:null => true, :precision => 30, :scale => 2, :default => 0.0}
      t.column :metric_units, :decimal, {:null => true, :precision => 30, :scale => 2, :default => 0.0}
      t.column :tyear, :integer, {:null => true}
      t.column :tmonth, :integer, {:null => true}
      t.column :tweek, :integer, {:null => true}
      t.column :tday, :integer, {:null => true}
    end
  end

  def self.down
    drop_table :easy_money_travel_costs
  end
end

class ModifyEasyCrmCaseItem < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :easy_crm_case_items, :price, :total_price

    change_column :easy_crm_case_items, :total_price, :decimal, {:null => false, :precision => 30, :scale => 2, :default => 0.0}

    add_column :easy_crm_case_items, :amount, :decimal, {:null => false, :precision => 30, :scale => 2, :default => 1.0}
    add_column :easy_crm_case_items, :product_code, :string, {:null => true, :limit => 255}
    add_column :easy_crm_case_items, :unit, :string, {:null => true, :limit => 255}
    add_column :easy_crm_case_items, :price_per_unit, :decimal, {:null => false, :precision => 30, :scale => 2, :default => 0.0}
  end

  def self.down
  end

end

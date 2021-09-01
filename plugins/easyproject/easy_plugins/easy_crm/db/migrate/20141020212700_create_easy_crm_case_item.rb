class CreateEasyCrmCaseItem < ActiveRecord::Migration[4.2]
  def self.up

    create_table :easy_crm_case_items, :force => true do |t|
      t.column :easy_crm_case_id, :integer, {:null => false}
      t.column :name, :string, {:null => false, :limit => 255}
      t.column :description, :string, {:null => true, :limit => 2048}
      t.column :price, :decimal, {:null => false, :precision => 30, :scale => 2}
      t.timestamps
    end
    add_index :easy_crm_case_items, [:easy_crm_case_id], :name => 'idx_ecci_1'

  end

  def self.down
    drop_table :easy_crm_case_items
  end

end

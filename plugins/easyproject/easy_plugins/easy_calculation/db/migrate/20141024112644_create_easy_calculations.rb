class CreateEasyCalculations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_calculations do |t|
      t.references :project, :null => false
      t.text :top_description
      t.text :bottom_description
      t.string :project_status
      t.string :supplier_name
      t.string :supplier_tel
      t.string :supplier_mail
      t.string :manager_name
      t.string :manager_tel
      t.string :manager_mail
    end
    add_index :easy_calculations, :project_id

    adapter_name = EasyCalculation.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_calculations, :top_description, :text, {:limit => 4294967295}
      change_column :easy_calculations, :bottom_description, :text, {:limit => 4294967295}
    end
  end

  def self.down
    drop_table :easy_calculations
  end
end

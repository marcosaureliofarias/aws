class AddMinMaxValueToCustomFields < ActiveRecord::Migration[4.2]
  def up
    add_column :custom_fields, :easy_min_value, :float, { :null => true }
    add_column :custom_fields, :easy_max_value, :float, { :null => true }
  end

  def down
    remove_column :custom_fields, :easy_min_value
    remove_column :custom_fields, :easy_max_value
  end
end

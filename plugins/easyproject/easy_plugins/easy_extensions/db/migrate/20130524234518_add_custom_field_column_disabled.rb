class AddCustomFieldColumnDisabled < ActiveRecord::Migration[4.2]
  def up
    add_column :custom_fields, :disabled, :boolean, :default => false, :null => false
  end

  def down
    remove_column :custom_fields, :disabled
  end
end

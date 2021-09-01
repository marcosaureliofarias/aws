class AddCustomFieldsShowOnList < ActiveRecord::Migration[4.2]
  def self.up
    add_column :custom_fields, :show_on_list, :boolean, { :null => false, :default => false }
  end

  def self.down
    remove_column :custom_fields, :show_on_list
  end
end

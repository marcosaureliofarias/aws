class AddCustomFieldCustomPermission < ActiveRecord::Migration[4.2]
  def up
    add_column :custom_fields, :easy_custom_permissions, :text
    remove_column(:custom_fields, :easy_permissions) if column_exists?(:custom_fields, :easy_permissions)
    CustomField.reset_column_information
    CustomField.descendants.each { |c| c.reset_column_information }
  end

  def down
    remove_column(:custom_fields, :easy_permissions) if column_exists?(:custom_fields, :easy_permissions)
    remove_column :custom_fields, :easy_custom_permissions
  end
end

class AddPermissionTypeToEasyPagePermission < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_page_permissions, :permission_type, :integer, { null: false, default: 0 }
    add_column :easy_pages, :strict_show_permissions, :boolean, default: false
  end
end

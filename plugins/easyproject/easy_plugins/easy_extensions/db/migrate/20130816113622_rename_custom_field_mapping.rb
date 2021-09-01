class RenameCustomFieldMapping < ActiveRecord::Migration[4.2]
  def up
    if table_exists?(:custom_field_mapping)
      rename_table :custom_field_mapping, :custom_field_mappings
    end
  end
end

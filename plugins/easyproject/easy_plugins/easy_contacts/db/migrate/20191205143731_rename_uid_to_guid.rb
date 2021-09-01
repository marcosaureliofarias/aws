class RenameUidToGuid < ActiveRecord::Migration[5.2]
  def up
    rename_column :easy_contacts, :uid, :guid
    add_easy_uniq_index :easy_contacts, :guid, name: 'idx_cont_guid'
    change_column_null(:easy_contacts, :guid, false)
  end

  def down
    change_column_null(:easy_contacts, :guid, true)
    remove_index :easy_contacts, name: 'idx_cont_guid'
    rename_column :easy_contacts, :guid, :uid
  end
end

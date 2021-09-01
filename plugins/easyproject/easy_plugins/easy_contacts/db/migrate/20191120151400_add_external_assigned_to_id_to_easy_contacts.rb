class AddExternalAssignedToIdToEasyContacts < ActiveRecord::Migration[4.2]
  def up
    change_table :easy_contacts do |t|
      t.column :external_assigned_to_id, :integer, null: true
    end
    add_index :easy_contacts, :external_assigned_to_id, name: 'idx_contacts_ext_assignee'
  end
end

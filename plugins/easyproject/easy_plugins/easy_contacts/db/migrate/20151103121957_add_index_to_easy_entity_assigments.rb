class AddIndexToEasyEntityAssigments < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_contact_entity_assignments, :easy_contact_id unless index_exists?(:easy_contact_entity_assignments, :easy_contact_id)
    add_index :easy_contacts_group_assignments, :contact_id unless index_exists?(:easy_contacts_group_assignments, :contact_id)
  end

  def down
  end
end
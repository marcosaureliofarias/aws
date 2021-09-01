class AddIndexesToContacts < ActiveRecord::Migration[4.2]
  def up
    add_easy_uniq_index :custom_fields_easy_contact_type, [:custom_field_id, :easy_contact_type_id], :name => 'idx_cfid_contacttypeid'
    # add_easy_uniq_index :custom_fields_easy_contacts, [:custom_field_id, :easy_contacts_id], :name => 'idx_cfid_contactid'
    # add_easy_uniq_index :custom_fields_easy_groups, [:custom_field_id, :easy_contact_groups_id], :name => 'idx_cfid_contactgroupid'
    add_easy_uniq_index :easy_contacts_group_assignments, [:contact_id, :group_id], :name => 'idx_contacts_groups'
    add_easy_uniq_index :easy_contacts_references, [:referenced_by, :referenced_to], :name => 'idx_contacts_references'
    add_easy_uniq_index :easy_contact_entity_assignments, [:easy_contact_id, :entity_id, :entity_type], :name => 'idx_contacts_assignments'
  end

  def down
  end
end

class AddIndexToContactsTree < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_contacts, [:root_id, :lft, :rgt], :name => 'idx_contacts_tree'
    add_index :easy_contacts, [:parent_id], :name => 'idx_contacts_parent_id'
  end

  def down
  end
end
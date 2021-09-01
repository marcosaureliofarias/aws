class AddIndexToEasyContacts < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_contacts, :private unless index_exists?(:easy_contacts, :private)
    add_index :easy_contacts, :author_id unless index_exists?(:easy_contacts, :author_id)
    add_index :easy_contacts, :type_id unless index_exists?(:easy_contacts, :type_id)
  end

  def down
  end
end

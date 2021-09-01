class ModificationsEasyContacts1 < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_contact_type, :internal_name, :string
    add_column :easy_contacts, :firstname, :string
    add_column :easy_contacts, :lastname, :string
  end
  
  def self.down
    remove_column :easy_contact_type, :internal_name
    remove_column :easy_contacts, :firstname
    remove_column :easy_contacts, :lastname
  end
end

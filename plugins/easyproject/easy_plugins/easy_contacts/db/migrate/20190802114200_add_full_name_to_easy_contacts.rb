class AddFullNameToEasyContacts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_contacts, :fullname, :string
  end
  
  def self.down
    remove_column :easy_contacts, :fullname
  end
end

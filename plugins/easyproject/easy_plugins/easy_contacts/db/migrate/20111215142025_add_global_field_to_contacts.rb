class AddGlobalFieldToContacts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_contacts, :is_global, :boolean, {:default => true}
  end

  def self.down
    remove_column :easy_contacts, :is_global
  end
end

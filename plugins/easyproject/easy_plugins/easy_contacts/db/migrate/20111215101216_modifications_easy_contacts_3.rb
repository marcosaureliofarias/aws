class ModificationsEasyContacts3 < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_contact_format_name', :value => :firstname_lastname)

    remove_column :easy_contacts, :contact_name
  end

  def self.down
    EasySetting.where({:name => 'easy_contact_format_name'}).destroy_all
    add_column :easy_contacts, :contact_name, :string
  end
end

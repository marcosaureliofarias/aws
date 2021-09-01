class AddUidToContacts < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_contacts, :uid, :string
  end

  def down
    remove_column :easy_contacts, :uid
  end

end

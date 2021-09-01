class AddEasyAvatarToEasyContacts < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_contacts, :easy_avatar, :string
  end
end

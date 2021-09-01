class AddEasyAvatarUrlToContacts < ActiveRecord::Migration[4.2]
  def up
    if !column_exists?(:easy_contacts, :easy_avatar_url)
      add_column :easy_contacts, :easy_avatar_url, :string, null: true
    end
  end

  def down
    remove_column :easy_contacts, :easy_avatar_url
  end
end

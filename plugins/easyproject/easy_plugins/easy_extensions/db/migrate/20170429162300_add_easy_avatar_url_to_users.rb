class AddEasyAvatarUrlToUsers < ActiveRecord::Migration[4.2]
  def up
    if !column_exists?(:users, :easy_avatar_url)
      add_column :users, :easy_avatar_url, :string, null: true
    end
  end

  def down
    remove_column :users, :easy_avatar_url
  end
end

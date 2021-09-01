class AddAvatarsCacheToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :easy_avatar, :string, { :length => 255, :null => true }
  end

  def down
    # plugins/easyproject/easy_plugins/easy_extensions/db/data/20140731696600_migrate_easy_avatars.rb:19
    # remove_column :users, :easy_avatar
  end
end

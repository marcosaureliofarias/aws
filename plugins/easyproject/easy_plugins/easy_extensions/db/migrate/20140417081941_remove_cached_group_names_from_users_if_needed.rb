class RemoveCachedGroupNamesFromUsersIfNeeded < ActiveRecord::Migration[4.2]
  def up
    remove_column(:users, :cached_group_names) if column_exists?(:users, :cached_group_names)
    User.reset_column_information
  end

  def down
  end
end

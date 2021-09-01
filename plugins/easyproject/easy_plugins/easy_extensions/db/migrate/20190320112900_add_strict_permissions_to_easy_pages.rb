class AddStrictPermissionsToEasyPages < RedmineExtensions::Migration

  def change
    add_column :easy_pages, :strict_permissions, :boolean, default: false
  end

end

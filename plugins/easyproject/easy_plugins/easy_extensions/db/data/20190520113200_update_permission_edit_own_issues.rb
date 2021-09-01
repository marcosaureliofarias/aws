class UpdatePermissionEditOwnIssues < EasyExtensions::EasyDataMigration
  def up
    Role.all.each do |role|
      role.add_permission! :edit_own_issues if role.permissions.include? :edit_own_issue
    end
  end

  def down
  end

end

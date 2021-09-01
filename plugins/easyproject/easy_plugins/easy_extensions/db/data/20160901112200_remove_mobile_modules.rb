class RemoveMobileModules < EasyExtensions::EasyDataMigration
  def up
    EasyPageModule.where(:type => ['EpmMobileIssueQuery', 'EpmMobileIssuesAssignedToMe']).delete_all
  end

  def down
  end
end
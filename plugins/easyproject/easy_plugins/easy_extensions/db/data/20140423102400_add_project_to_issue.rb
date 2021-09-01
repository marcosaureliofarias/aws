class AddProjectToIssue < EasyExtensions::EasyDataMigration
  def self.up
    EasySetting.create! name: 'display_project_field_on_issue_detail', value: false
  end
end

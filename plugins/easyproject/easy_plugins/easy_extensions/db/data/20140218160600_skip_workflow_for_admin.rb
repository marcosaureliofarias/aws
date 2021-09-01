class SkipWorkflowForAdmin < EasyExtensions::EasyDataMigration
  def self.up
    EasySetting.create! name: 'skip_workflow_for_admin'
  end
end

class SetEasyHelpdeskAutoIssueCloserModes < EasyExtensions::EasyDataMigration
  def up
    EasyHelpdeskAutoIssueCloser.where(auto_update_modes: []).update_all(auto_update_modes: [:change])
  end

  def down
  end
end

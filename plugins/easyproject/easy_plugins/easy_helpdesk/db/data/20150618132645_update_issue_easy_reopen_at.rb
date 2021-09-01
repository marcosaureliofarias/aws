class UpdateIssueEasyReopenAt < EasyExtensions::EasyDataMigration
  def up
    Issue.update_all('easy_reopen_at = created_on')
  end

  def down
  end
end

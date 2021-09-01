class ChangeIssueRecalculateAttributes < EasyExtensions::EasyDataMigration
  def up
    s = EasySetting.where(:name => 'change_issue_recalculate_attributes', :project_id => nil).first

    if s && s.value
      Setting.set_from_params 'parent_issue_dates', 'derived'
      Setting.set_from_params 'parent_issue_priority', 'derived'
      Setting.set_from_params 'parent_issue_done_ratio', 'derived'
    else
      Setting.set_from_params 'parent_issue_dates', 'independent'
      Setting.set_from_params 'parent_issue_priority', 'independent'
      Setting.set_from_params 'parent_issue_done_ratio', 'independent'
    end

  end

  def down
  end

end

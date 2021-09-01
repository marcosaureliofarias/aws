class CopyIssueEasySprintRelationSprintIdToIssue < ActiveRecord::Migration[4.2]
  def up
    EasySprint.all.each do |easy_sprint|
      issues_to_update = easy_sprint.issue_easy_sprint_relations.where("issue_id IS NOT NULL").pluck(:issue_id)

      Issue.where(:id => issues_to_update).update_all(:easy_sprint_id => easy_sprint.id)
    end
  end

  def down
  end
end

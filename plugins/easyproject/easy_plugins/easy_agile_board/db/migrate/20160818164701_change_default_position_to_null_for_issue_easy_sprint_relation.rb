class ChangeDefaultPositionToNullForIssueEasySprintRelation < ActiveRecord::Migration[4.2]
  def up
    change_column :issue_easy_sprint_relations, :position, :integer, { :null => true, :default => nil }
  end

  def down
  end
end

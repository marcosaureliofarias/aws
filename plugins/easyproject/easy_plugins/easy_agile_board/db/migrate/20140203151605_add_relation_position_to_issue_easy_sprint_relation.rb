class AddRelationPositionToIssueEasySprintRelation < ActiveRecord::Migration[4.2]
  def change
    add_column :issue_easy_sprint_relations, :relation_position, :integer
  end
end

class ChangeRelationTypes < ActiveRecord::Migration[4.2]
  PREVIOUS_BACKLOG = 1
  PREVIOUS_PROGRESS = 2
  PREVIOUS_DONE = 3

  NEW_BACKLOG = -1
  NEW_DONE = -2

  def up
    IssueEasySprintRelation.where(relation_type: PREVIOUS_BACKLOG).update_all(relation_type: NEW_BACKLOG)
    IssueEasySprintRelation.where(relation_type: PREVIOUS_PROGRESS).update_all('relation_type = relation_position')
    IssueEasySprintRelation.where(relation_type: PREVIOUS_DONE).update_all(relation_type: NEW_DONE)
  end
end

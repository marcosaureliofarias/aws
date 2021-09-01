class RecalculatePositionsInAgileLists < ActiveRecord::Migration[4.2]
  def up
    # reorder IssueEasySprintRelation lists
    lists = IssueEasySprintRelation.reorder(:position).group_by {|relation| [relation.easy_sprint_id, relation.relation_type, relation.relation_position] }
    lists.values.each do |items|
      items.each_with_index do |sprint_relation, i|
        IssueEasySprintRelation.where(:id => sprint_relation.id).update_all(:position => i+1)
      end
    end

    # reorder EasyAgileBacklogRelation lists
    lists = EasyAgileBacklogRelation.reorder(:position).group_by {|relation| [relation.project_id] }
    lists.values.each do |items|
      items.each_with_index do |backlog_relation, i|
        EasyAgileBacklogRelation.where(:id => backlog_relation.id).update_all(:position => i+1)
      end
    end
  end
end

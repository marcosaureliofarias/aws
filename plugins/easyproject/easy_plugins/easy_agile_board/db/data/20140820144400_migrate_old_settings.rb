class MigrateOldSettings < ActiveRecord::Migration[4.2]

  def up
    EasySetting.where(:name => 'agile_board_statuses').each do |set|
      h = set.value

      h[IssueEasySprintRelation::TYPE_PROGRESS].keys.each do |idx|
        h[IssueEasySprintRelation::TYPE_PROGRESS][idx]['state_statuses'] = Array.wrap(h[IssueEasySprintRelation::TYPE_PROGRESS][idx]['status_id'])
        if h[IssueEasySprintRelation::TYPE_PROGRESS][idx]['return_to_author'] == '1'
          h[IssueEasySprintRelation::TYPE_PROGRESS][idx]['return_to'] = '__author__'
        else
          h[IssueEasySprintRelation::TYPE_PROGRESS][idx]['return_to'] = '__no_change__'
        end
      end

      h[IssueEasySprintRelation::TYPE_DONE]['state_statuses'] = Array.wrap(h[IssueEasySprintRelation::TYPE_DONE]['status_id'])
      if h[IssueEasySprintRelation::TYPE_DONE]['return_to_author'] == '1'
        h[IssueEasySprintRelation::TYPE_DONE]['return_to'] = '__author__'
      else
        h[IssueEasySprintRelation::TYPE_DONE]['return_to'] = '__no_change__'
      end

      set.value = h
      set.save
    end
  end

  def down
  end
end

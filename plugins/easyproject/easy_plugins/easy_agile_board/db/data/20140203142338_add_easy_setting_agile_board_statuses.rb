class AddEasySettingAgileBoardStatuses < ActiveRecord::Migration[4.2]
  def up
    settings = Setting.plugin_easy_agile_board
    EasySetting.create(:name => 'agile_board_statuses', :value => {
      IssueEasySprintRelation::TYPE_DONE => { 'status_id' => settings['done_status_id'] },
      IssueEasySprintRelation::TYPE_PROGRESS => {
        1 => { 'name' => 'New', 'status_id' => settings['new_status_id']},
        2 => { 'name' => 'Realization', 'status_id' => settings['realization_status_id']},
        3 => { 'name' => 'To check', 'status_id' => settings['to_check_status_id']}
      }
    })
  end

  def down
  end
end

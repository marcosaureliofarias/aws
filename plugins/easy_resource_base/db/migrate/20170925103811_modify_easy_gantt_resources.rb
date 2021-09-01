class ModifyEasyGanttResources < ActiveRecord::Migration[4.2]

  def up
    add_column(:easy_gantt_resources, :start, :time)
    add_index(:easy_gantt_resources, [:user_id, :issue_id, :date, :start], unique: true, name: 'unique_index_user_id_and_issue_id_and_date_and_start')
  end

  def down
    remove_index(:easy_gantt_resources, name: 'unique_index_user_id_and_issue_id_and_date_and_start')
    remove_column(:easy_gantt_resources, :start)
  end

end

class ChangeEasyHelpdeskProjectSlaHoursNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null(:easy_helpdesk_project_slas, :hours_to_solve, true)
    change_column_null(:easy_helpdesk_project_slas, :hours_to_response, true)
  end
end

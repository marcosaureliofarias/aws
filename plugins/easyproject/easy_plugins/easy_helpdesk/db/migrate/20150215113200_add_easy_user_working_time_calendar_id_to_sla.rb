class AddEasyUserWorkingTimeCalendarIdToSla < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_project_slas, :easy_user_working_time_calendar_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :easy_user_working_time_calendar_id
  end
end
class AddWorkingWeekDaysToEasyUserWorkingTimeCalendar < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_user_time_calendars, :working_week_days, :text
    EasyUserTimeCalendar.reset_column_information
    EasyUserWorkingTimeCalendar.reset_column_information
  end

  def down
    remove_column :easy_user_time_calendars, :working_week_days
  end

end

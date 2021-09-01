class AddIcalUrlToEasyUserWorkingTimeCalendar < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_user_time_calendars, :ical_url, :text
    EasyUserTimeCalendar.connection.schema_cache.clear!
    EasyUserTimeCalendar.reset_column_information
  end

  def down
    remove_column :easy_user_time_calendars, :ical_url
  end

end

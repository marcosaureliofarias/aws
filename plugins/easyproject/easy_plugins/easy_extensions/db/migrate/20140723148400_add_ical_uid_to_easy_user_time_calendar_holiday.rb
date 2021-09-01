class AddIcalUidToEasyUserTimeCalendarHoliday < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_user_time_calendar_holidays, :ical_uid, :text
    EasyUserTimeCalendarHoliday.reset_column_information

    add_index :easy_user_time_calendar_holidays, [:calendar_id, :ical_uid], :unique => true, :name => 'index_ical_uid', :length => { :ical_uid => 255 }
  end

  def down
  end

end

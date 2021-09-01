class DestroyDuplicateWorkingTimeCalendars < ActiveRecord::Migration[4.2]
  def up
    User.all.each do |u|
      calendar          = EasyUserWorkingTimeCalendar.where(:user_id => u.id).first
      working_calendars = EasyUserWorkingTimeCalendar.arel_table
      if calendar
        calendar_ids = EasyUserWorkingTimeCalendar.where(:user_id => u.id).where(['id <> ?', calendar.id]).pluck(:id)

        EasyUserTimeCalendarHoliday.where(:calendar_id => calendar_ids).delete_all
        EasyUserTimeCalendarException.where(:calendar_id => calendar_ids).delete_all

        EasyUserWorkingTimeCalendar.where(:id => calendar_ids).delete_all
      end
    end
  end

  def down
  end
end

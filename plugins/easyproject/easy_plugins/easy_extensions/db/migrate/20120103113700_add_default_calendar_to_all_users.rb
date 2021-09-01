class AddDefaultCalendarToAllUsers < ActiveRecord::Migration[4.2]
  def self.up
    default_calendar = EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil, :is_default => true).first

    User.all.each do |user|
      default_calendar.assign_to_user(user, true)
    end if default_calendar

  end

  def self.down
  end
end
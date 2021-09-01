class AddShowInMeetingCalendarToUserType < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_user_types, :show_in_meeting_calendar, :boolean, { :null => false, :default => true }
  end

  def self.down
    remove_column :easy_user_types, :show_in_meeting_calendar
  end
end

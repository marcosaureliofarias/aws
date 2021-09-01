class AddEmailNotificationsToEasyMeetings < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_meetings, :email_notifications, :integer, default: EasyMeeting.email_notifications[:right_now]
  end
end

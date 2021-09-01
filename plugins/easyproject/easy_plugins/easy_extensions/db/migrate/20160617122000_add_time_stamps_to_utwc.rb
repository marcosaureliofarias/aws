class AddTimeStampsToUtwc < ActiveRecord::Migration[4.2]
  def up
    add_timestamps :easy_user_time_calendars, default: Time.now
  end

  def down
    remove_column :easy_user_time_calendars, :created_at
    remove_column :easy_user_time_calendars, :updated_at
  end
end

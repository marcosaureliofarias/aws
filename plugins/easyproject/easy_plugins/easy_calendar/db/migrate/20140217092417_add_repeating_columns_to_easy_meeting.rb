class AddRepeatingColumnsToEasyMeeting < ActiveRecord::Migration[4.2]
  def up
    EasyMeeting.migrate_repeating_columns
  end
  def down
    EasyMeeting.migrate_repeating_columns(:down)
  end
end

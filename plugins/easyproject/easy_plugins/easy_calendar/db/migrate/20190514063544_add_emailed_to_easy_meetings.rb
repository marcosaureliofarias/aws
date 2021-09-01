class AddEmailedToEasyMeetings < ActiveRecord::Migration[5.2]
  def up
    add_column :easy_meetings, :emailed, :boolean, default: false
  end

  def down
    remove_column :easy_meetings, :emailed
  end
end

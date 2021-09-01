class AddBigRecurringToEasyMeetings < ActiveRecord::Migration[4.2]

  def change
    add_column :easy_meetings, :big_recurring, :boolean, default: false
  end

end

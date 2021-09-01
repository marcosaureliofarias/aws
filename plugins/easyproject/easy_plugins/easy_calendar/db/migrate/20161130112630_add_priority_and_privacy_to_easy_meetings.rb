class AddPriorityAndPrivacyToEasyMeetings < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_meetings, :priority, :integer, null: false, default: EasyMeeting.priorities[:normal]
    add_column :easy_meetings, :privacy, :integer, null: false, default: EasyMeeting.privacies[:xpublic]
  end

  def down
    remove_column :easy_meetings, :priority
    remove_column :easy_meetings, :privacy
  end

end

class AddOrModifyMailsOnEasyMeetings < ActiveRecord::Migration[4.2]

  def up
    if column_exists?(:easy_meetings, :mails)
      # Column used to be a string
      change_column :easy_meetings, :mails, :text
    else
      add_column :easy_meetings, :mails, :text
    end
  end

  def down
    remove_column :easy_meetings, :mails
  end

end

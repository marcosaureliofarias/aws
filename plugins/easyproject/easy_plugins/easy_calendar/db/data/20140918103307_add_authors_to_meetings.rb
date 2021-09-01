class AddAuthorsToMeetings < ActiveRecord::Migration[4.2]
  def up

    EasyMeeting.joins(:author).preload(:author).where("#{User.table_name}.id IS NOT NULL").find_each(:batch_size => 50) do |meeting|
      Mailer.with_deliveries(false) do
        meeting.user_ids += Array(meeting.author_id)
        meeting.accept!(meeting.author)
      end
    end
  end
  def down
    EasyMeeting.find_each(:batch_size => 50) do |meeting|
      Mailer.with_deliveries(false) do
        meeting.users.delete(meeting.author) if meeting.author
      end
    end
  end
end

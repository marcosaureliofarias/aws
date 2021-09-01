class AddUuidToEasyMeetings < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_meetings, :uid, :string, null: true

    EasyMeeting.reset_column_information
    Mailer.with_deliveries(false) do
      EasyMeeting.where(:uid => nil).find_each(batch_size: 50) do |meeting|
        meeting.update_column(:uid, EasyUtils::UUID.generate)
      end
    end
    change_column :easy_meetings, :uid, :string, null: false
  end

  def down
    remove_column :easy_meetings, :uid
  end
end

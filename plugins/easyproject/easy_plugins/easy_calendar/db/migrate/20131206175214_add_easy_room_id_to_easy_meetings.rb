class AddEasyRoomIdToEasyMeetings < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_meetings, :easy_room_id, :integer
    add_index :easy_meetings, :easy_room_id
  end
end

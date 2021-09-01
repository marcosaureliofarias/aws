class AddEasyRepeatParentIdToEasyMeetings < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_meetings, :easy_repeat_parent_id, :integer, :null => true
    add_index :easy_meetings, :easy_repeat_parent_id
  end
end

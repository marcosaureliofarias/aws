class AddIndexTimeEntryIdToEasyAttendances < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_attendances, :time_entry_id, :name => 'idx_ea_time_entry_id'
  end

  def down
    remove_index :easy_attendances, :name => 'idx_ea_time_entry_id'
  end
end

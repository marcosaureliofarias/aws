class AddTimeEntryIdToEasyAttendances < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_attendances, :time_entry_id, :integer, { :null => true }
  end

  def self.down
    remove_column :easy_attendances, :time_entry_id
  end
end

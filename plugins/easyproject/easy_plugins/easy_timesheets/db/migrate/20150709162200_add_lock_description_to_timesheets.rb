class AddLockDescriptionToTimesheets < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_timesheets, :lock_description, :text, {:null => true}
  end

  def down
    remove_column :easy_timesheets, :lock_description
  end
end

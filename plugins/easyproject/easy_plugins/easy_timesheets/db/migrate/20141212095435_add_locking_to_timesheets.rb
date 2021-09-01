class AddLockingToTimesheets < ActiveRecord::Migration[4.2]
  def up
    change_table :easy_timesheets do |t|
      t.boolean(:locked, :default => false, :null => false)

      t.belongs_to(:locked_by, :null => true)
      t.datetime(:locked_at, :null => true)

      t.belongs_to(:unlocked_by, :null => true)
      t.datetime(:unlocked_at, :null => true)
    end
  end

  def down
    change_table :easy_timesheets do |t|
      t.remove(:locked)

      t.remove(:locked_by_id)
      t.remove(:locked_at)
      t.remove(:unlocked_by_id)
      t.remove(:unlocked_at)
    end
  end
end

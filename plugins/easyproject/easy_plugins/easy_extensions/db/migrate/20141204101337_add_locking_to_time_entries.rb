class AddLockingToTimeEntries < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(:name => 'time_entries_locking_enabled', :value => false)

    change_table :time_entries do |t|
      t.boolean(:easy_locked, :default => false, :null => false)

      t.belongs_to(:easy_locked_by, :null => true)
      t.datetime(:easy_locked_at, :null => true)

      t.belongs_to(:easy_unlocked_by, :null => true)
      t.datetime(:easy_unlocked_at, :null => true)
    end
  end

  def down
    EasySetting.where(:name => 'time_entries_locking_enabled').delete_all

    change_table :time_entries do |t|
      t.remove(:easy_locked)

      t.remove(:easy_locked_by_id)
      t.remove(:easy_locked_at)
      t.remove(:easy_unlocked_by_id)
      t.remove(:easy_unlocked_at)
    end
  end
end

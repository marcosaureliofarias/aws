class CreateEasyTimesheets < ActiveRecord::Migration[4.2]
  def self.up

    create_table :easy_timesheets, :force => true do |t|
      t.string :period, :null => true
      t.belongs_to :user, {:null => false}
      t.date :start_date, {:null => false}
      t.date :end_date, {:null => false}

      t.timestamps
    end

    add_index :easy_timesheets, [:user_id], :name => 'idx_et_1'
    add_index :easy_timesheets, [:user_id, :start_date, :end_date], :name => 'idx_et_2'

    add_column :time_entries, :easy_timesheet_id, :integer, {:null => true}

    add_index :time_entries, [:easy_timesheet_id], :name => 'idx_te_eti1'
  end

  def self.down
    drop_table :easy_timesheets

    remove_column :time_entries, :easy_timesheet_id
  end
end

class CreateEasyAttendanceActivityUserLimits < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_attendance_activity_user_limits do |t|
      t.references :easy_attendance_activity
      t.references :user
      t.column :days, :float, :null => false
      t.column :accumulated_days, :float, :null => false, :default => 0.0
    end
    add_index :easy_attendance_activity_user_limits, :user_id, :name => 'eaaul_u_id'
    add_index :easy_attendance_activity_user_limits, [:easy_attendance_activity_id, :user_id], :name => 'eaaul_eaa_id', :unique => true
  end

  def down
    drop_table :easy_attendance_activity_user_limits
  end
end
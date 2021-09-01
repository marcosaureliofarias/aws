class RegisterRakeAttendanceActivityAccumulation < ActiveRecord::Migration[4.2]
  def self.up
    EasyRakeTaskAttendanceActivityAccumulation.reset_column_information
    t         = EasyRakeTaskAttendanceActivityAccumulation.new(:active      => true, :settings => {}, :period => :monthly, :interval => 12,
                                                               :next_run_at => Time.local(Date.today.year, 12, 31, 23, 0))
    t.builtin = 1
    t.save!
  end

  def self.down
    EasyRakeTaskAttendanceActivityAccumulation.destroy_all
  end
end

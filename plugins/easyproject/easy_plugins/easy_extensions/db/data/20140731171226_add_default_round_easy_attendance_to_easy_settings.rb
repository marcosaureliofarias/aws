class AddDefaultRoundEasyAttendanceToEasySettings < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(:name => 'round_easy_attendance_to_quarters', :value => true)
  end

  def down
    EasySetting.where(:name => 'round_easy_attendance_to_quarters').delete_all
  end
end

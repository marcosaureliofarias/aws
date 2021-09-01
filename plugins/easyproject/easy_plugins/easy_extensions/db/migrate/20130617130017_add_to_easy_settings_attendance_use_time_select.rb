class AddToEasySettingsAttendanceUseTimeSelect < ActiveRecord::Migration[4.2]
  def change
    EasySetting.create(:name => 'easy_attendance_use_time_select', :value => false)
  end
end

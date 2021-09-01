class MoveTimesheetSettingsFromRys < ActiveRecord::Migration[5.2]
  def self.up
    # Migrate over_time form RYS feature to EasySetting
    easy_timesheets_over_time = EasySetting.find_or_create_by(name: 'easy_timesheets_over_time')
    easy_timesheets_over_time.update(value: Rys::Feature.active?('extended_timesheet.over_time'))
    # Migrate custom_field_overtime_id form RYS settings to easy_timesheets settings
    easy_timesheets_custom_field_overtime_id = EasySetting.find_or_create_by(name: 'easy_timesheets_custom_field_overtime_id')
    easy_timesheets_custom_field_overtime_id.update(value: EasySetting.value('extended_timesheet_custom_field_overtime_id'))
    EasySetting.where(name: 'extended_timesheet_custom_field_overtime_id').destroy_all
    # Migrate easy_timesheets_enabled_timesheet_calendar setting form multi selecect format to only one value
    calendar_type = EasySetting.find_or_create_by(name: 'easy_timesheets_enabled_timesheet_calendar')
    new_calendar_type_value = if calendar_type.value == ['day']
      'week'
    else
      'month'
    end
    calendar_type.update(value: new_calendar_type_value)
    # Update old timesheets week periods
    EasyTimesheet.where(period: nil).update_all(period: 'week')
  end

  def self.down
    RysFeatureRecord.activate!('extended_timesheet.over_time') if EasySetting.value('easy_timesheets_over_time')
    EasySetting.where(name: 'easy_timesheets_over_time').destroy_all

    extended_timesheets_custom_field_overtime_id = EasySetting.find_or_create_by(name: 'extended_timesheet_custom_field_overtime_id')
    extended_timesheets_custom_field_overtime_id.update(value: EasySetting.value('easy_timesheets_custom_field_overtime_id'))
    EasySetting.where(name: 'easy_timesheets_custom_field_overtime_id').destroy_all

    calendar_type = EasySetting.find_or_create_by(name: 'easy_timesheets_enabled_timesheet_calendar')
    new_calendar_type_value = if calendar_type.value == 'week'
      ['day']
    else
      ['month']
    end
    calendar_type.update(value: new_calendar_type_value)
    EasyTimesheet.where(period: 'week').update_all(period: nil)
  end
end

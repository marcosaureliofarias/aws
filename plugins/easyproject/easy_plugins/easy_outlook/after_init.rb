ActiveSupport.on_load(:easyproject, yield: true) do
  if EasySetting.table_exists?
    setting = EasySetting.find_or_initialize_by(name: 'easy_calendar_extended_caldav')
    setting.value = true
    setting.save!
  end
end

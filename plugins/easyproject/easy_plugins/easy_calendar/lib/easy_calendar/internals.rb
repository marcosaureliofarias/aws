module EasyCalendar

  def self.extended_caldav?
    !!EasySetting.value(:easy_calendar_extended_caldav)
  end

end

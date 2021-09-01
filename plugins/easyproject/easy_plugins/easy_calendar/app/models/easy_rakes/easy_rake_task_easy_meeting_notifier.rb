class EasyRakeTaskEasyMeetingNotifier < EasyRakeTask

  def execute
    EasyMeeting.easy_to_notify.each do |meeting|
      EasyCalendar::EasyMeetingNotifier.call(meeting)
    end

    return true
  end

  def category_caption_key
    :label_calendar
  end

  def registered_in_plugin
    :label_calendar
  end
end

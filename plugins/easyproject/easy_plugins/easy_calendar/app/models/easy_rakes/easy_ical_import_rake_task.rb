class EasyIcalImportRakeTask < EasyRakeTask

  def execute
    EasyIcalendar.not_running.find_each(batch_size: 50) do |ical|
      ical.in_background = true
      ImportIcalEventsJob.perform_now(ical)
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

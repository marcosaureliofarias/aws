module EasyActivitiesHelper

  def event_update_datetime(event)
    event.try(:updated_on) || event.try(:updated_at) || event.event_datetime
  end

  def event_last_journal(event)
    if event.respond_to?(:journals) && (journal = event.journals.visible.with_notes.last) && (journal.notes.present?)
      return journal
    end
    nil
  end

  def link_to_easy_attendance_activity(activity)
    return nil unless activity.present?
    link_to(activity, edit_easy_attendance_activity_path(activity), class: activity.color_schema)
  end

end

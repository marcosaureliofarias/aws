class ImportIcalEventsJob < EasyActiveJob
  # self.queue_adapter = :sidekiq
  # queue_as :default

  def perform(icalendar)
    return if icalendar.in_progress?

    icalendar.in_progress!
    log_info "   Import ical ##{icalendar.id} #{icalendar.status}"

    EasyCalendar::IcalendarImportService.call(icalendar)

    log_info "   Import ical ##{icalendar.id} #{icalendar.status}"
    log_info "   Import ical ##{icalendar.id} #{icalendar.message}" if icalendar.failed?

    # notify
    # if Redmine::Plugin.installed?(:easy_instant_messages) && !icalendar.in_background?
    #   if icalendar.success?
    #     msg = I18n.t(:notice_ical_import_events_ready, name: icalendar.name)
    #   elsif icalendar.failed?
    #     msg = I18n.t(:error_ical_import_events_failed, name: icalendar.name)
    #   end
    #   EasyInstantMessage.create(sender: AnonymousUser.last, recipient: icalendar.user, content: msg.html_safe) if msg.present?
    # end

    return true

  rescue StandardError => e
    msg = e.message.truncate(30_000) # 30 000 is max length of text column
    icalendar.failed_import!(msg)
  end
end

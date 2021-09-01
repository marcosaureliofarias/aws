module EasyCalendar
  class IcalendarImportService
    include EasyIcalHelper

    attr_reader :calendar

    def initialize(ical)
      @calendar = ical
    end

    # ical is instance of EasyIcalendar
    def self.call(ical)
      service = new(ical)
      service.from_ical
      service
    end

    def from_ical
      import
    end

    def success?
      @calendar.success?
    end

    def failed?
      @calendar.failed?
    end

    def synchronize_events
      return if @ical.nil?
      error = nil
      EasyIcalendarEvent.transaction do
        @calendar.events.delete_all
        begin
          @ical.events.map do |event|
            ical_event = EasyIcalendarEvent.new(uid: event.uid)
            ical_event.summary = event.summary
            ical_event.dtstart = event.dtstart
            ical_event.dtend = event.dtend
            ical_event.description = event.description
            ical_event.organizer = event.organizer
            ical_event.url = event.url
            ical_event.is_private = !(event.ip_class.blank? || event.ip_class == 'PUBLIC')
            ical_event.easy_icalendar = @calendar
            ical_event.save!
          end
        rescue StandardError => e
          error = e.message
          raise ActiveRecord::Rollback
        rescue ActiveRecord::RecordInvalid => invalid
          error = invalid.record.errors.full_messages.join(',')
          raise ActiveRecord::Rollback
        end
      end

      if error
        @calendar.failed_import!(error)
      else
        @calendar.success_import!
      end
    end

    private

    def import
      @ical = load_icalendar(@calendar.url)
    rescue StandardError, Timeout::Error => e
      @calendar.failed_import!(e.message)
    else
      if @ical.nil?
        @calendar.failed_import!(I18n.t(:notice_ical_import_events_failed))
      else
        synchronize_events
      end
    end
  end
end

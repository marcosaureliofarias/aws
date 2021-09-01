module EasyCalendar
  class AdvancedCalendar
    include Redmine::I18n

    @registered_calendars = {}

    class << self
      attr_accessor :registered_calendars
    end

    def self.register(klass)
      ActiveSupport::Deprecation.warn("Deprecated calendar: #{klass}, please use EasyAdvancedCalendar") unless EasyCalendar::AdvancedCalendars::EasyAdvancedCalendar.descendants.include?(klass)
      registered_calendars[klass.name.split('::').last.underscore.to_sym] = klass
    end

    def self.allowed_registered_calendars
      registered_calendars.select{|id, klass| check_permission(klass)}
    end

    def self.check_permission(klass)
      user = User.current
      if klass.respond_to?(:permissions)
        return false if Array(klass.permissions).detect{|p| !user.allowed_to?(p, nil, :global => true)}
      end
      if klass.respond_to?(:runtime_permissions)
        return false unless klass.runtime_permissions
      end
      true
    end

    def self.events(start_date, end_date, options = {})
      options ||= {}
      options[:enabled_calendars] ||= []

      events = []
      allowed_registered_calendars.each do |id, klass|
        if options[:enabled_calendars].include?(id.to_s)
          calendar = new_calendar(klass, options)
          events << (calendar.events(start_date, end_date) || [])
        end
      end
      return events.flatten.uniq{|e| e[:id] }
    end

    def self.project_events(start_date, end_date, project, options = {})
      options ||= {}
      options[:enabled_calendars] ||= []

      events = []
      allowed_registered_calendars.each do |id, klass|
        next if !options[:enabled_calendars].include?(id.to_s)
        calendar = new_calendar(klass, options)
        if calendar.respond_to?(:project_events)
          events << (calendar.project_events(start_date, end_date, project) || [])
        end
      end
      return events.flatten
    end

    def self.room_events(start_date, end_date, room, options = {})
      events = []
      allowed_registered_calendars.each do |id, klass|
        calendar = new_calendar(klass, options)
        if calendar.respond_to?(:room_events)
          events << (calendar.room_events(start_date, end_date, room) || [])
        end
      end
      return events.flatten
    end

    def self.calendars_data(ctrl=nil)
      data = {}
      ctrl ||= self
      allowed_registered_calendars.each do |id, klass|
        data[id] = {
          :label => l(klass.label),
        }
        if klass.respond_to?(:new_record_path)
          data[id][:new_record_path] = ctrl.send(klass.new_record_path)
        end
        if klass.respond_to?(:new_record_path)
          data[id][:create_record_path] = ctrl.send(klass.create_record_path, format: :json)
        end
      end
      data
    end

    private

    def self.new_calendar(klass, options)
      if EasyCalendar::AdvancedCalendars::EasyAdvancedCalendar.descendants.include?(klass)
        klass.new(options[:controller])
      else
        klass.new
      end
    end

  end
end

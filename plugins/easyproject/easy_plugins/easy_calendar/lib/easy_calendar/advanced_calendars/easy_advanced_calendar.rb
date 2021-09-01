module EasyCalendar
  module AdvancedCalendars
    class EasyAdvancedCalendar
      def self.has_project_events?
        false
      end

      def self.has_room_events?
        false
      end

      def initialize(controller)
        if controller.nil?
          raise ArgumentError, "Controller cannot be nil!"
        end
        @controller = controller
      end
    end
  end
end
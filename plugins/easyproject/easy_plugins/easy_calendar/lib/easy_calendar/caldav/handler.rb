module EasyCalendar
  module Caldav
    class Handler < EasyExtensions::Webdav::Handler

      def controller_class
        EasyCalendar::Caldav::Controller
      end

      def service_name
        'caldav'
      end

      def enabled?
        EasySetting.value('easy_caldav_enabled')
      end

    end
  end
end

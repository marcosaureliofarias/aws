module EasyCalendar
  module Caldav
    class Resource < EasyExtensions::Webdav::Resource

      def header_dav
        ['calendar-access']
      end

      def current_user_principal
        render_xml_element do |xml|
          xml['d'].href('/caldav/principal/')
        end
      end

      def owner
        current_user_principal
      end

      def principal_url
        current_user_principal
      end

      def calendar_home_set
        render_xml_element do |xml|
          xml['d'].href('/caldav/')
        end
      end

      def calendar_user_address_set
        render_xml_element do |xml|
          xml['d'].href("mailto:#{User.current.mail}")
          xml['d'].href('/caldav/principal/')
        end
      end

    end
  end
end

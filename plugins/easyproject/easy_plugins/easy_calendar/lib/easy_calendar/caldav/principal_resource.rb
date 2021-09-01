module EasyCalendar
  module Caldav
    class PrincipalResource < Resource

      def collection?
        true
      end

      def property_names
        ['resourcetype', 'current-user-principal', 'displayname', 'calendar-home-set'].freeze
      end

      def allowed_methods
        ['OPTIONS', 'PROPFIND'].freeze
      end

      def resourcetype
        render_xml_element do |xml|
          xml['d'].collection
          xml['d'].principal
        end
      end

      def displayname
        User.current.name
      end

    end
  end
end

module EasyCalendar
  module Caldav
    class EntityResource < Resource
      include Redmine::I18n

      def initialize(path, controller, entity=nil)
        super(path, controller)
        @entity = entity || find_entity
      end

      def collection?
        false
      end

      def allowed_methods
        ['OPTIONS', 'HEAD', 'GET', 'PUT', 'PROPFIND'].freeze
      end

      def property_names
        ['resourcetype', 'getetag', 'getcontenttype', 'displayname', 'getcontentlength', 'getlastmodified', 'creationdate', 'calendar-data'].freeze
      end

      def entity
        @entity || raise(NotFound)
      end

      def exist?
        !!@entity
      end

      def errors_full_messages
        @entity && @entity.errors.full_messages.join(', ')
      end

      def getcontenttype
        'text/calendar'
      end

      def calendar_data
        @calendar_data ||= EasyExtensions::Webdav::CData.new(_calendar_data)
      end

      def getcontentlength
        calendar_data.bytesize.to_s
      end

      def to_text(text)
        Redmine::WikiFormatting::HtmlParser.to_text(text.to_s)
      end

      def append_x_alt_desc(event, value)
        alt_desc_value = Icalendar::Values::Text.new(value, fmttype: 'text/html')
        event.append_custom_property('X-ALT-DESC', alt_desc_value)
      end

      # HTTP GET request
      #
      def get
        response.body = calendar_data
      end

    end
  end
end

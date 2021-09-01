module EasyContacts
  module Carddav
    class VcardResource < Resource

      def initialize(path, controller, entity=nil)
        super(path, controller)
        @entity = entity || find_entity
      end

      def entity
        @entity || raise(NotFound)
      end

      def exist?
        !!@entity
      end

      def collection?
        false
      end

      def getcontenttype
        'text/vcard'
      end

      def displayname
        entity.name
      end

      def getcontentlength
        address_data.bytesize.to_s
      end

      def getlastmodified
        entity.updated_on.httpdate
      end

      def creationdate
        entity.created_on.iso8601
      end

      # HTTP Requests
      # =======================================================================

      def get
        response.body = address_data
      end

    end
  end
end

require 'vcard'

module EasyContacts
  module Carddav
    ##
    # EasyContactResource
    #
    # Easy contact entity
    #
    class EasyContactResource < VcardResource
      include EasyContactsHelper

      def allowed_methods
        ['OPTIONS', 'HEAD', 'GET', 'PUT', 'PROPFIND', 'REPORT', 'DELETE'].freeze
      end

      def property_names
        ['resourcetype', 'getetag', 'getcontenttype', 'displayname', 'getcontentlength', 'getlastmodified', 'creationdate', 'address-data'].freeze
      end

      def getetag
        "\"#{entity.etag}\""
      end

      def address_data
        @address_data ||= Redmine::CodesetUtil.safe_from_utf8(vcard_export(entity).first, 'UTF-8')
      end

      def find_entity
        uid = path.split('/').last
        uid.sub!(/\.vcf\Z/, '')

        EasyContact.visible.find_by(guid: uid)
      end


      # HTTP Requests
      # =======================================================================

      # If client will try to create VLIST => 500
      def put
        force_create = (request.env['HTTP_IF_NONE_MATCH'] == '*')

        # Client intends to create a new address resource
        raise Conflict if force_create && exist?

        request.body.rewind
        request_body = Redmine::CodesetUtil.replace_invalid_utf8(request.body.read)
        vcard = Vcard::Vcard.decode(request_body).first

        # Save current state for response HTTP status
        new_record = exist? ? false : true

        # Entity should get the same UID because client will ask for it
        @entity ||= EasyContact.new(guid: vcard.value('UID'))
        @entity.type_id ||= EasyContactType.default.try(:id)

        # Return `@entity.save`
        saved = vcard_import(@entity, vcard)

        return saved, new_record
      end

      def delete
        entity.destroy
      end

    end
  end
end

module EasyContacts
  module Carddav
    ##
    # EasyContactResource
    #
    # Collection of easy contacts
    #
    class EasyContactsResource < AddressBookResource

      def controlled_access?
        true
      end

      def readable?
        true
      end

      def writeable?
        true
      end

      def entities
        EasyContact.visible
      end

      def last_updated
        entities.order(updated_on: :desc).first
      end

      def grouped_entities_by_uid(uid)
        entities.where(guid: uid).group_by(&:guid)
      end

      def child(entity)
        EasyContactResource.new(path + '/' + entity.guid + '.vcf', controller, entity)
      end

      def displayname
        I18n.t(:label_easy_contacts)
      end

    end
  end
end

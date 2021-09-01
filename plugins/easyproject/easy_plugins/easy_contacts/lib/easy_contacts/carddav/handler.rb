module EasyContacts
  module Carddav
    ##
    # EasyContacts::Carddav::Handler
    #
    # Handler
    # `-- Controller
    #     `-- Resource
    #         |-- Principal
    #         |-- AddressBooks
    #         |-- AddressBook
    #         |   |-- EasyContacts
    #         |   `-- Users
    #         `-- Vcard
    #             |-- EasyContact
    #             `-- User
    #
    class Handler < EasyExtensions::Webdav::Handler

      def controller_class
        EasyContacts::Carddav::Controller
      end

      def service_name
        'carddav'
      end

      def enabled?
        EasySetting.value('easy_carddav_enabled')
      end

    end
  end
end

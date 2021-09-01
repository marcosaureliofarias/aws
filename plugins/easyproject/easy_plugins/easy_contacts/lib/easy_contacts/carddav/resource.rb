module EasyContacts
  module Carddav
    class Resource < EasyExtensions::Webdav::Resource

      def header_dav
        ['addressbook']
      end

      def current_user_principal
        render_xml_element do |xml|
          xml['d'].href('/carddav/principal')
        end
      end

      def owner
        current_user_principal
      end

      def addressbook_home_set
        render_xml_element do |xml|
          xml['d'].href('/carddav')
        end
      end

    end
  end
end

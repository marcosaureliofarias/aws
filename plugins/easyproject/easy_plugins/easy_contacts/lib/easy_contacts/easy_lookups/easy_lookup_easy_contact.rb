require 'easy_extensions/easy_lookups/easy_lookup'

module EasyContacts
  module EasyLookups
    class EasyLookupEasyContact < EasyExtensions::EasyLookups::EasyLookup

      def attributes
        [
          [l(:field_contact_name), 'name'],
          [l(:label_link_with, :attribute => l(:field_contact_name)), 'link_with_name'],
          [l(:label_link_with_and_custom_field, :attribute => l(:field_contact_name)), 'name_and_cf']
        ]
      end

    end
  end
end

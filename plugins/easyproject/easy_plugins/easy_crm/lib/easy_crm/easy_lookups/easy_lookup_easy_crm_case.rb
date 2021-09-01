require 'easy_extensions/easy_lookups/easy_lookup'

module EasyCrm
  module EasyLookups
    class EasyLookupEasyCrmCase < EasyExtensions::EasyLookups::EasyLookup

      def attributes
        [
          [EasyCrmCase.human_attribute_name("name"), 'name'],
          [l(:label_link_with, :attribute => EasyCrmCase.human_attribute_name("name")), 'link_with_name'],
          [l(:label_link_with_and_custom_field, :attribute => EasyCrmCase.human_attribute_name("name")), 'name_and_cf']
        ]
      end

    end
  end
end

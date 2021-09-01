require 'easy_extensions/easy_lookups/easy_lookup'

module EasyExtensions
  module EasyLookups
    class EasyLookupDocument < EasyLookup

      def attributes
        [
            [l(:field_title), 'title'],
            [l(:label_link_with, :attribute => l(:field_title)), 'link_with_title'],
            [l(:label_link_with_and_custom_field, :attribute => l(:field_title)), 'name_and_cf']
        ]
      end

    end
  end
end

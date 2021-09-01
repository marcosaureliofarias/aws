require 'easy_extensions/easy_lookups/easy_lookup'

module EasyExtensions
  module EasyLookups
    class EasyLookupVersion < EasyLookup

      def attributes
        version_attributes = [
            [l(:field_name), 'name'],
            [l(:label_link_with, :attribute => l(:field_name)), 'link_with_name']
        ].concat(super)
        version_attributes << [l(:label_name_and_date, :attribute => l(:field_name)), 'name_and_date']
        version_attributes
      end

    end
  end
end

require 'easy_extensions/easy_lookups/easy_lookup'

module EasyExtensions
  module EasyLookups
    class EasyLookupProject < EasyLookup

      def attributes
        [
            [l(:field_name), 'name'], [l(:label_link_with, :attribute => l(:field_name)), 'link_with_name']
        ].concat(super)
      end

    end
  end
end

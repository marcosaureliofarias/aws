require 'easy_extensions/easy_lookups/easy_lookup'

module EasyExtensions
  module EasyLookups
    class EasyLookupGroup < EasyLookup

      def attributes
        [
            [l(:field_name), 'lastname'], [l(:label_link_with, :attribute => l(:field_name)), 'link_with_lastname']
        ].concat(super)
      end

    end
  end
end

require 'easy_extensions/easy_lookups/easy_lookup'

module EasyExtensions
  module EasyLookups
    class EasyLookupUser < EasyLookup

      def attributes
        attributes_for_select = [
            [l(:field_name), 'name'],
            [l(:label_link_with, :attribute => l(:field_name)), 'link_with_name']
        ]
        attributes_for_select.concat(super)
        attributes_for_select << [l(:field_mail), 'mail']
        attributes_for_select
      end

    end
  end
end

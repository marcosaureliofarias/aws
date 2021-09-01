require 'easy_extensions/easy_lookups/easy_lookup'

module EasyMoney
  module EasyLookups
    class EasyLookupEasyMoneyExpectedExpense < EasyExtensions::EasyLookups::EasyLookup

      def attributes
        [
          [l(:field_name), 'name'],
          [l(:label_link_with, attribute: l(:field_name)), 'link_with_name'],
          [l(:label_link_with_and_custom_field, attribute: l(:field_name)), 'name_and_cf']
        ]
      end

    end
  end
end

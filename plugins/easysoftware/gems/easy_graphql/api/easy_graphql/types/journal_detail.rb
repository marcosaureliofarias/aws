# frozen_string_literal: true

module EasyGraphql
  module Types
    class JournalDetail < Base

      field :id, ID, null: false
      field :property, String, null: true
      field :prop_key, String, null: true
      field :old_value, String, null: true
      field :value, String, null: true
      field :as_string, String, null: true do
        argument :html, Boolean, 'Add html tags', default_value: true, required: false
      end

      def as_string(html:)
        cleared_issues_helpers.details_to_strings([object], !html, only_path: true).first
      end

    end
  end
end

# frozen_string_literal: true

module EasyGraphql
  module Types
    class Tracker < Base

      field :id, ID, null: false
      field :name, String, null: true
      field :enabled_fields, [String], null: false
      field :disabled_fields, [String], null: false

      def enabled_fields
        ::Tracker::CORE_FIELDS_ALL - object.disabled_core_fields
      end

      def disabled_fields
        object.disabled_core_fields
      end

    end
  end
end

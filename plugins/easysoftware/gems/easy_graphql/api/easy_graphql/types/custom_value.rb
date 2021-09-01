# frozen_string_literal: true

module EasyGraphql
  module Types
    class CustomValue < Base

      field :id, ID, null: false
      field :custom_field, Types::CustomField, null: false
      field :easy_external_id, String, null: true
      field :editable, Boolean, null: true, method: :inline_editable?
      field :possible_values, [GraphQL::Types::JSON], null: true

      field :value, GraphQL::Types::JSON, null: true
      field :formatted_value, String, null: true

      field :edit_tag, String, null: true do
        argument :prefix, String,
                 'Prefix for an input',
                 default_value: 'graphql',
                 required: false
      end

      def possible_values
        cf = object.custom_field
        case cf.field_format
        when 'enumeration', 'country'
          cf.possible_values_options
        when 'version', 'user'
          cf.possible_values_options(object.customized)
        else
          cf.possible_values
        end
      end

      def formatted_value
        issue_controller.view_context.show_value(object, false)
      end

      def edit_tag(prefix:)
        issue_controller.view_context.custom_field_tag(prefix, object)
      end

    end
  end
end

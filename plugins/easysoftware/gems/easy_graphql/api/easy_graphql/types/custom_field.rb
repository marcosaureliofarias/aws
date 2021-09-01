# frozen_string_literal: true

module EasyGraphql
  module Types
    class CustomField < Base

      field :id, ID, null: false
      field :type, String, null: false
      field :name, String, null: false
      field :description, String, null: true
      field :field_format, String, null: false
      field :internal_name, String, null: true
      field :multiple, Boolean, null: false
      field :is_required, Boolean, null: false
      field :default_value, String, null: true
      field :editable, Boolean, null: true
      field :settings, GraphQL::Types::JSON, null: true
      field :format_store, GraphQL::Types::JSON, null: true
      field :easy_group, Types::EasyGroup, null: true

    end
  end
end

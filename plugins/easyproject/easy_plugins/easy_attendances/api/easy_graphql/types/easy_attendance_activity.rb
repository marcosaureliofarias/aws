# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyAttendanceActivity < Base

      field :id, ID, null: false
      field :name, String, null: true
      field :internal_name, String, null: true
      field :color_schema, String, null: true
      field :position, Integer, null: true
      field :at_work, Boolean, null: true
      field :is_default, Boolean, null: true
      field :non_deletable, Boolean, null: true
      field :approval_required, Boolean, null: true
      field :use_specify_time, Boolean, null: true
      field :system_activity, Boolean, null: true
      field :created_at, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: true

    end
  end
end

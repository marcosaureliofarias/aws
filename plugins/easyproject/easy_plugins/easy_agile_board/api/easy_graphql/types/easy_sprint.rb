# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasySprint < Base
      description 'Sprint'

      field :name, String, null: true
      field :project, Types::Project, null: true
      field :start_date, Types::Scalars::Date, null: true
      field :due_date, Types::Scalars::Date, null: true
      field :version, Types::Version, null: true
      field :capacity, Int, null: true
      field :goal, String, null: true
      field :cross_project, Boolean, null: true
      field :closed, Boolean, null: true
      field :created_at, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: true

    end
  end
end

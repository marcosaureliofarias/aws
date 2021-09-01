# frozen_string_literal: true

module EasyGraphql
  module Types
    class Version < Base

      field :id, ID, null: false
      field :name, String, null: false
      field :description, String, null: false
      field :status, String, null: false
      field :sharing, String, null: false
      field :project, Types::Project, null: true
      field :due_date, Types::Scalars::Date, null: true
      field :created_on, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_on, GraphQL::Types::ISO8601DateTime, null: true

    end
  end
end

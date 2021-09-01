module EasyGraphql
  module Types
    class EasyIcalendar < Base
      field :id, ID, null: false
      field :name, String, null: false
      field :url, String, null: false
      field :visibility, Boolean, null: true
      field :synchronized_at, GraphQL::Types::ISO8601DateTime, null: true
      field :last_run_at, GraphQL::Types::ISO8601DateTime, null: true
      field :status, Integer, null: true
      field :message, String, null: true
      field :user, Types::User, null: false
    end
  end
end
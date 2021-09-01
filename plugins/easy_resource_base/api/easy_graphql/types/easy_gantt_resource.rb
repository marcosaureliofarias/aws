# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyGanttResource < Base
      description 'EasyGanttResource'

      self.entity_class = 'EasyGanttResource'

      field :id, ID, null: false
      field :user, Types::User, null: false
      field :issue, Types::Issue, null: false
      field :date, Types::Scalars::Date, null: false
      field :start_time, GraphQL::Types::ISO8601DateTime, null: true
      field :end_time, GraphQL::Types::ISO8601DateTime, null: true
      field :hours, Float, null: false
      field :original_hours, Float, null: false
      field :custom, Boolean, null: true

      def start_time
        object.full_date&.to_time
      end

      def end_time
        if start_time
          start_time.advance(hours: object.hours)
        else
          nil
        end
      end
    end
  end
end

# frozen_string_literal: true

module EasyGraphql
  module Mutations
    class EasyAttendanceUpdate < Base
      description 'Update EasyAttendance.'

      argument :easy_attendance_id, ID, required: true, loads: Types::EasyAttendance
      argument :attributes, GraphQL::Types::JSON, required: true
      argument :non_work_start_time, GraphQL::Types::JSON, required: false

      field :easy_attendance, Types::EasyAttendance, null: true
      field :errors, [Types::Error], null: true

      def authorized?(**args)
        return false, response_record_not_found unless entity

        if entity.can_edit?
          true
        else
          [false, response_record_not_authorized]
        end
      end

      def resolve(easy_attendance:, attributes:)
        entity.init_journal(::User.current)
        set_non_work_start_time(attributes)
        entity.safe_attributes = attributes
        entity.ensure_easy_attendance_non_work_activity
        if entity.save
          response_entity
        else
          response_errors
        end
      end

      def set_non_work_start_time(attributes)
        non_work_start_time = attributes.delete('non_work_start_time') || {}
        non_work_start_time[:time] = non_work_start_time['time']
        entity.non_work_start_time = non_work_start_time if non_work_start_time
      end

    end
  end
end

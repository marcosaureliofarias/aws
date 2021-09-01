# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyAttendance < Base

      self.entity_class = 'EasyAttendance'

      has_journals

      field :id, ID, null: false
      field :arrival, GraphQL::Types::ISO8601DateTime, null: true, method: :arrival_time_in_user_time_zone
      field :departure, GraphQL::Types::ISO8601DateTime, null: true, method: :departure_time_in_user_time_zone
      field :easy_attendance_activity, Types::EasyAttendanceActivity, null: true
      field :allowed_activities, [Types::EasyAttendanceActivity], null: true
      field :user, Types::User, null: true
      field :edited_by, Types::User, null: true
      field :edited_when, GraphQL::Types::ISO8601DateTime, null: true
      field :locked, Boolean, null: true
      field :created_at, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
      field :arrival_user_ip, String, null: true
      field :departure_user_ip, String, null: true
      field :time_entry, Types::TimeEntry, null: true
      field :allowed_ranges, [Types::HashKeyValue], null: true
      field :range, Types::HashKeyValue, null: true
      field :description, String, null: true
      field :approval_status, Types::HashKeyValue, null: true
      field :previous_approval_status, Integer, null: true
      field :approved_by, Types::User, null: true
      field :approved_at, GraphQL::Types::ISO8601DateTime, null: true
      field :hours, Float, null: true
      field :can_edit, Boolean, null: true, method: :can_edit?
      field :can_edit_users, Boolean, null: true
      field :can_approve, Boolean, null: true, method: :can_approve?
      field :can_request_cancel, Boolean, null: true, method: :can_request_cancel?
      field :can_delete, Boolean, null: true, method: :can_delete?
      field :need_approve, Boolean, null: true, method: :need_approve?
      field :working_time, Float, null: true
      field :evening, GraphQL::Types::ISO8601DateTime, null: true
      field :morning, GraphQL::Types::ISO8601DateTime, null: true

      def working_time
        object.working_time(true)
      end

      def evening
        object.evening(object.arrival || Date.today)
      end

      def morning
        object.morning(object.departure || Date.today)
      end

      def allowed_activities
        ::EasyAttendanceActivity.user_activities.sorted.to_a
      end

      def approval_status
        return nil unless object.approval_status

        { key: object.approval_status, value: object.attendance_status }
      end

      def allowed_ranges
        [::EasyAttendance::RANGE_FULL_DAY, ::EasyAttendance::RANGE_FORENOON, ::EasyAttendance::RANGE_AFTERNOON].map do |ran|
          prepare_range(ran)
        end
      end

      def range
        return nil if !object.activity || object.activity.use_specify_time

        prepare_range(object.range.presence || ::EasyAttendance::DEFAULT_RANGE)
      end

      def prepare_range(ran)
        { key: ran, value: I18n.t(range_lang_key(ran), scope: [:easy_attendance, :range]) }
      end

      def range_lang_key(ran)
        case ran
        when ::EasyAttendance::RANGE_FULL_DAY
          :full_day
        when ::EasyAttendance::RANGE_FORENOON
          :forenoon
        when ::EasyAttendance::RANGE_AFTERNOON
          :afternoon
        end
      end

      def can_edit_users
        ::User.current.allowed_to?(:edit_easy_attendances, nil, global: true)
      end

    end
  end
end

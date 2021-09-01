# frozen_string_literal: true

module EasyGraphql
  module Resolvers
    class EasyAttendancesApproval < Resolvers::Base
      description 'EasyAttendances which need to be approved'

      type EasyGraphql::Types::EasyAttendancesApproval, null: true

      argument :ids, [GraphQL::Types::ID], required: false
      argument :user_ids, [GraphQL::Types::ID], required: false

      def resolve(ids: [], user_ids: [])
        easy_attendances = []

        if ::User.current.allowed_to_globally?(:edit_easy_attendance_approval, {})
          easy_attendances = ::EasyAttendance.approval_required
          easy_attendances = easy_attendances.where(id: ids) if ids.any?
          easy_attendances = easy_attendances.where(user_id: user_ids) if user_ids.any?
        end

        {
            easy_attendances: easy_attendances,
            is_exceeded: ::EasyAttendance.check_limit_exceeded(easy_attendances)
        }
      end

    end
  end
end

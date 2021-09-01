# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyAttendancesApproval < Base

      field :easy_attendances, [EasyGraphql::Types::EasyAttendance], null: true, hash_key: :easy_attendances
      field :is_exceeded, Boolean, null: true, hash_key: :is_exceeded

    end
  end
end

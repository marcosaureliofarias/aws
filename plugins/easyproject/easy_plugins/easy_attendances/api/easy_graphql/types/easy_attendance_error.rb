# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyAttendanceError < Base

      field :attribute, String, null: false
      field :full_messages, [String], null: false
      field :user, EasyGraphql::Types::User, null: false

    end
  end
end

# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyInvitation < Base

      field :user, Types::User, null: true
      field :accepted, Boolean, null: true
      field :alarms, String, null: true

      def user
        object.user if object.user&.visible?
      end

    end
  end
end

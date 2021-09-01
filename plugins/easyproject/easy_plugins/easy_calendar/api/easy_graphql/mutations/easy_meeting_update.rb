# frozen_string_literal: true

module EasyGraphql
  module Mutations
    class EasyMeetingUpdate < Base
      description 'Update EasyMeeting.'

      argument :easy_meeting_id, ID, required: true, loads: Types::EasyMeeting
      argument :attributes, GraphQL::Types::JSON, required: true

      field :easy_meeting, EasyGraphql::Types::EasyMeeting, null: true
      field :errors, [String], null: true

      def authorized?(**args)
        return false, response_record_not_found unless entity

        if entity.editable?
          true
        else
          [false, response_record_not_authorized]
        end
      end

      def resolve(easy_meeting:, attributes:)
        entity.safe_attributes = attributes
        if entity.save
          response_all
        else
          { errors: prepare_errors }
        end
      end

      def prepare_errors
        entity.errors.full_messages
      end
    end
  end
end

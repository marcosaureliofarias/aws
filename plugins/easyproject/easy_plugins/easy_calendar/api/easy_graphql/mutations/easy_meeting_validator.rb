module EasyGraphql
  module Mutations
    class EasyMeetingValidator < Base
      description 'Expect all EasyMeeting attributes for new record.
                   Expect changed EasyMeeting attributes for edit record.
                   Return error object with validation messages.'

      argument :id, ID, required: false
      argument :attributes, GraphQL::Types::JSON, required: true

      field :easy_meeting, Types::EasyMeeting, null: true
      field :errors, [Types::Error], null: true

      def resolve(attributes:, id: nil)
        self.entity = prepare_easy_meeting(id)
        return response_record_not_found unless entity

        entity.safe_attributes = attributes
        entity.valid?

        response_all
      end

      private

        def prepare_easy_meeting(id)
          if id
            ::EasyMeeting.find_by(id: id)
          else
            ::EasyMeeting.new
          end
        end

    end
  end
end

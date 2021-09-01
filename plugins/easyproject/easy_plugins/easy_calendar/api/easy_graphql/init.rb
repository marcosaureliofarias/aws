# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Query') do

  field :easy_meeting, EasyGraphql::Types::EasyMeeting, null: true do
    description 'Find meeting by ID'
    argument :id, GraphQL::Types::ID, required: true
  end

  field :easy_icalendar_event, EasyGraphql::Types::EasyIcalendarEvent, null: true do
    description 'Find ICalendar event by ID'
    argument :id, GraphQL::Types::ID, required: true
  end

  def easy_meeting(id:)
    meeting = ::EasyMeeting.find_by(id: id)

    if meeting&.visible?
      meeting
    else
      nil
    end
  end

  def easy_icalendar_event(id:)
    EasyIcalendarEvent.find_by(id: id)
  end

end

EasyGraphql.patch('EasyGraphql::Types::Mutation') do
  field :easy_meeting_update, mutation: EasyGraphql::Mutations::EasyMeetingUpdate
  field :easy_meeting_validator, mutation: EasyGraphql::Mutations::EasyMeetingValidator
end

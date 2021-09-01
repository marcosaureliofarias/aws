module EasyGraphql
  module Types
    class EasyIcalendarEvent < Base
      self.entity_class = 'EasyICalendarEvent'

      field :id, ID, null: false
      field :summary, String, null: true
      field :easy_icalendar, Types::EasyIcalendar, null: false
      field :uid, String, null: false
      field :dtstart, GraphQL::Types::ISO8601DateTime, null: true
      field :dtend, GraphQL::Types::ISO8601DateTime, null: true
      field :description, String, null: true
      field :location, String, null: true
      field :organizer, String, null: true
      field :url, String, null: true
      field :is_private, Boolean, null: true
    end
  end
end
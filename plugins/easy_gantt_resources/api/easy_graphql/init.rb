# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::EasyMeeting') do
  field :easy_resource_dont_allocate, GraphQL::Types::Boolean, null: true
end

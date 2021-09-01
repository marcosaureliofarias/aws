# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Query') do

  field :all_easy_entity_activities, [EasyGraphql::Types::EasyEntityActivity], null: false do
    extension EasyGraphql::Extensions::EasyQuery, query_klass: EasyEntityActivityQuery
  end

  field :easy_entity_activity, EasyGraphql::Types::EasyEntityActivity, null: true do
    description 'Find Sales activity by ID'
    argument :id, GraphQL::Types::ID, required: true
  end

  def easy_entity_activity(id:)
    ::EasyEntityActivity.find_by(id: id)
  end
end

EasyGraphql.patch('EasyGraphql::Types::Mutation') do
  field :easy_entity_activity, mutation: EasyGraphql::Mutations::EasyEntityActivity
  field :easy_entity_activity_validator, mutation: EasyGraphql::Mutations::EasyEntityActivityValidator
end

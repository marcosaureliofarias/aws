# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Query') do
  field :easy_gantt_resources, [EasyGraphql::Types::EasyGanttResource], null: false do
    description 'Issue EasyGanttResource list'
    argument :issue_id, [GraphQL::Types::ID], required: true
  end
  field :easy_gantt_resource, EasyGraphql::Types::EasyGanttResource, null: true do
    description 'Find EasyGanttResource by ID'
    argument :id, GraphQL::Types::ID, required: true
  end

  def easy_gantt_resource(id:)
    ::EasyGanttResource.find_by(id: id)
  end

  def easy_gantt_resources(issue_id:)
    ::EasyGanttResource.where(issue_id: Issue.visible.where(id: issue_id))
  end
end

EasyGraphql.patch('EasyGraphql::Types::Mutation') do
  field :easy_gantt_resource, mutation: EasyGraphql::Mutations::EasyGanttResource
  field :easy_gantt_resource_validator, mutation: EasyGraphql::Mutations::EasyGanttResourceValidator
end

# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Issue') do
  field :easy_sprint, EasyGraphql::Types::EasySprint, null: true
  field :easy_story_points, GraphQL::Types::Int, null: true
  field :easy_sprint_visible, GraphQL::Types::Boolean, 'Is field visible for current issue', null: true
  field :easy_sprint_editable, GraphQL::Types::Boolean, 'Is field editable for current issue', null: true

  def easy_sprint_visible
    ::PermissionResolver.visible?(object, :easy_sprint)
  end

  def easy_sprint_editable
    ::PermissionResolver.editable?(object, :easy_sprint)
  end

end

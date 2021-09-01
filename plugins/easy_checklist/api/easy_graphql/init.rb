# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Issue') do
  field :checklists, [EasyGraphql::Types::EasyChecklist], null: true, method: :easy_checklists
end

EasyGraphql.patch('EasyGraphql::Types::Project') do
  field :visible_checklists, GraphQL::Types::Boolean, null: false
  field :addable_checklists, GraphQL::Types::Boolean, null: false
  field :addable_checklist_items, GraphQL::Types::Boolean, null: false

  def visible_checklists
    object.module_enabled?(:easy_checklists) && ::User.current.allowed_to?(:view_easy_checklists, object)
  end

  def addable_checklists
    ::User.current.allowed_to?(:create_easy_checklists, object)
  end

  def addable_checklist_items
    ::User.current.allowed_to?(:create_easy_checklist_items, object)
  end
end

EasyGraphql.patch('EasyGraphql::Types::Mutation') do
  field :checklist_change, mutation: EasyGraphql::Mutations::EasyChecklistChange
  field :checklist_destroy, mutation: EasyGraphql::Mutations::EasyChecklistDestroy
  field :checklist_item_change, mutation: EasyGraphql::Mutations::EasyChecklistItemChange
  field :checklist_item_destroy, mutation: EasyGraphql::Mutations::EasyChecklistItemDestroy
end

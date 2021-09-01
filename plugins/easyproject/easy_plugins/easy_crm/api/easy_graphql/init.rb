# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Query') do
  field :all_easy_crm_cases, [EasyGraphql::Types::EasyCrmCase], null: false do
    extension EasyGraphql::Extensions::EasyQuery, query_klass: EasyCrmCaseQuery
  end

  field :easy_crm_case, EasyGraphql::Types::EasyCrmCase, null: true do
    description 'Find Crm case by ID'
    argument :id, GraphQL::Types::ID, required: true
  end

  def easy_crm_case(id:)
    ::EasyCrmCase.visible.find_by(id: id)
  end
end

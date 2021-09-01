# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Query') do
  field :all_easy_contacts, [EasyGraphql::Types::EasyContact], null: false do
    extension EasyGraphql::Extensions::EasyQuery, query_klass: EasyContactQuery
  end

  field :easy_contact, EasyGraphql::Types::EasyContact, null: true do
    description 'Find Contact by ID'
    argument :id, GraphQL::Types::ID, required: true
  end

  def easy_contact(id:)
    ::EasyContact.visible.find_by(id: id)
  end
end

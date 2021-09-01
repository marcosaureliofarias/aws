EasyGraphql.patch('EasyGraphql::Types::Issue') do
  field :duration, GraphQL::Types::Int, null: true, method: :easy_duration
  field :available_duration_units, [EasyGraphql::Types::HashKeyValue], null: true

  def available_duration_units
    units = ::I18n.t('issue_duration.time_units')
    return {} unless units.is_a?(Hash)

    units.map do |(key, value)|
      { key: key.to_s, value: value }
    end
  end
end

EasyGraphql.patch('EasyGraphql::Types::Mutation') do
  field :issue_duration, mutation: EasyGraphql::Mutations::IssueDuration
end

# frozen_string_literal: true

module EasyGraphql
  class AppSchema < GraphQL::Schema
    query Types::Query
    mutation Types::Mutation
  end
end

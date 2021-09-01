# frozen_string_literal: true

module EasyGraphql
  module Types
    module Enums
      class SortOrder < GraphQL::Schema::Enum
        value 'ASC', 'ascending'
        value 'DESC', 'Descending'
      end
    end
  end
end

# frozen_string_literal: true

module EasyGraphql
  module Types
    module Scalars
      class Date < GraphQL::Schema::Scalar
        description 'An ISO 8601-encoded Date'

        # @param value [Date]
        # @return [String]
        def self.coerce_result(value, _ctx)
          value.iso8601
        end

        # @param value [String]
        # @return [Date]
        def self.coerce_input(value, _ctx)
          ::Date.iso8601(value)
        rescue ArgumentError
          nil
        end

      end
    end
  end
end

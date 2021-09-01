# frozen_string_literal: true

module EasyExtensions
  module QueryString
    class Transform < Parslet::Transform

      # {value:{array:[{value:{string:"1"}}]}}

      rule(string: simple(:string)) { string.to_s }
      # => {value:{array:[{value:"1"}]}}

      rule(value: simple(:value)) { value.to_s }
      # => {value:{array:["1"]}}

      rule(array: sequence(:array)) { array }
      # => {value:["1"]}

      # Transform cannot create a loop.
      # Each node will be replaced only once and then left alone.
      # That meands that the result of a replacement will stay as it is.

      # { field: status_id, operator: '=', value1: '1', value: '2' }
      rule(field: simple(:field), operator: simple(:operator), value1: simple(:value1), value2: simple(:value2)) {
        EasyExtensions::QueryString::Transform.filter_into_sql(easy_query, field, operator, [value1, value2])
      }

      # { field: status_id, operator: '=', value: ['1', '2'] }
      rule(field: simple(:field), operator: simple(:operator), value: sequence(:value)) {
        EasyExtensions::QueryString::Transform.filter_into_sql(easy_query, field, operator, value)
      }

      # { field: status_id, operator: '=', value: '1' }
      rule(field: simple(:field), operator: simple(:operator), value: simple(:value)) {
        EasyExtensions::QueryString::Transform.filter_into_sql(easy_query, field, operator, value)
      }

      rule(filter: simple(:filter)) { filter }

      rule(and: { left: subtree(:left), right: subtree(:right) }) {
        "(#{left} AND #{right})"
      }

      rule(or: { left: subtree(:left), right: subtree(:right) }) {
        "(#{left} OR #{right})"
      }

      def self.filter_into_sql(easy_query, field, operator, values)
        sql = easy_query.filter_statement(field.to_s, operator.to_s, values, validate: true)
        sql || '(1=1)'
      end

    end
  end
end

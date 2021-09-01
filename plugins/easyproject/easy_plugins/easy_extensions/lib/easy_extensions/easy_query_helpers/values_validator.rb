# frozen_string_literal: true

module EasyExtensions
  module EasyQueryHelpers
    class ValuesValidator
      class Error < StandardError;
      end

      ID_REGEX      = /\A\d+\z/
      INTEGER_REGEX = /\A[+-]?\d+\z/
      FLOAT_REGEX   = /\A[+-]?\d+[.,]?\d*\z/
      COUNTRY_REGEX = /\A\S+\z/
      BOOLEANS      = ['0', '1', 't', 'f', 'true', 'false']

      attr_reader :query

      def initialize(query)
        @query = query
      end

      def valid?(field, operator, value)
        filter_definition = query.available_filters[field]
        values            = Array(value).map { |v| v.to_s.strip }

        case filter_definition[:type]
        when :integer
          values.all? { |v| INTEGER_REGEX.match?(v) || query.integer_value_valid?(field, v) }

        when :float
          values.all? { |v| FLOAT_REGEX.match?(v) }

        when :boolean
          values.all? { |v| BOOLEANS.include?(v) }

        when :country_select
          values.all? { |v| COUNTRY_REGEX.match?(v) }

        # Lets assume that every values are IDs
        when :list_autocomplete, :list_status, :list_version, :list_optional, :list_subprojects, :relation, :easy_lookup, :tree
          if query.entity && column = query.entity.columns.find { |column| column.name == field }
            case column.type
            when :integer
              values.all? { |v| INTEGER_REGEX.match?(v) || query.integer_value_valid?(field, v) }
            when :float
              values.all? { |v| FLOAT_REGEX.match?(v) }
            when :boolean
              values.all? { |v| BOOLEANS.include?(v) }
            else
              values.all? { |v| ID_REGEX.match?(v) }
            end
          else
            values.all? { |v| ID_REGEX.match?(v) }
          end

        else
          true
        end
      end

    end
  end
end

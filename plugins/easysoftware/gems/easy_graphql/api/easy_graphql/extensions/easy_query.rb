# frozen_string_literal: true

module EasyGraphql
  module Extensions
    class EasyQuery < GraphQL::Schema::FieldExtension

      def apply
        input_maker = InputsMaker.new(options[:query_klass])

        field.description options[:query_klass].name

        field.argument :filter, input_maker.make_filter, required: false
        field.argument :sort, input_maker.make_sort, required: false if input_maker.any_sortable_column?
        field.argument :limit, Integer, required: false
        field.argument :offset, Integer, required: false
        field.argument :page, Integer, required: false
      end

      def resolve(object:, arguments:, **rest)
        query = options[:query_klass].new

        if arguments.has_key?(:filter)
          arguments[:filter].each do |filter, values|
            filter = filter.to_s.gsub('__', '.')

            values.each do |operator, value|
              if value.is_a?(Array)
                value = value.dup.map(&:to_s)
              else
                value = value.dup.to_s
              end

              case operator
              when :match
                query.add_filter(filter, '~', value)
              when :not_match
                query.add_filter(filter, '!~', value)
              when :opened
                query.add_filter(filter, 'o', nil)
              when :closed
                query.add_filter(filter, 'c', nil)
              when :eq
                query.add_filter(filter, '=', value)
              when :gteq
                query.add_filter(filter, '>=', value)
              when :lteq
                query.add_filter(filter, '<=', value)
              when :between
                query.add_filter(filter, '><', value)
              end

              # Only one filter can be used
              # You cannot do: `{ subject: { eq: "test1", not_eq: "test2" } }`
              break
            end
          end
        end

        if arguments.has_key?(:sort)
          sort_criteria = []
          arguments[:sort].each do |field, order|
            field = field.to_s.gsub('__', '.')
            sort_criteria << [field, order.to_s.downcase]
          end

          query.sort_criteria = sort_criteria
        end

        offset, limit = ApplicationController.new.api_offset_and_limit({
          limit: arguments[:limit],
          offset: arguments[:offset],
          page: arguments[:page],
        })

        query.entities(limit: limit, offset: offset)
      end

      class InputsMaker

        attr_reader :query_klass, :query, :main_input

        def initialize(query_klass)
          @query_klass = query_klass

          User.current.as_admin {
            @query = query_klass.new
          }
        end

        def make_filter
          User.current.as_admin do
            @main_input = Class.new(GraphQL::Schema::InputObject)
            @main_input.graphql_name "#{query_klass}Filter"
            add_filters
            @main_input
          end
        end

        def make_sort
          User.current.as_admin do
            @main_input = Class.new(GraphQL::Schema::InputObject)
            @main_input.graphql_name "#{query_klass}Sort"
            add_sorts
            @main_input
          end
        end
        
        def any_sortable_column?
          query.available_columns.any?(&:sortable?)
        end

        private

          def operator_name(operator)
            I18n.t(::EasyQuery.operators[operator])
          end

          def add_filters
            query.available_filters.each do |filter_name, filter_options|
              filter_name = filter_name.gsub('.', '__')
              add_filter(filter_name, filter_options)
            end
          end

          def add_sorts
            query.available_columns.each do |column|
              if column.sortable?
                name = column.name.to_s.gsub('.', '__')
                main_input.argument name, Types::Enums::SortOrder, required: false
              end
            end
          end

          def create_filter_input(filter_name, filter_options)
            filter_input = Class.new(GraphQL::Schema::InputObject)

            # Dont forget a prefix to prevent duplicite a type name definition
            # @see {GraphQL::Schema::Traversal#visit}
            filter_input.graphql_name("#{query_klass}_#{filter_name}")
            filter_input.description(filter_options[:name])

            yield filter_input

            main_input.argument filter_name, filter_input, required: false
          end

          def add_filter(filter_name, filter_options)
            arguments = []

            case filter_options[:type]
            when :text
              arguments << [:match, String, '~']
              arguments << [:not_match, String, '!~']

            when :list_status
              arguments << [:opened, GraphQL::Types::Boolean, 'o']
              arguments << [:closed, GraphQL::Types::Boolean, 'c']
              arguments << [:eq, [GraphQL::Types::ID], '=']

            when :list, :list_autocomplete, :list_optional
              arguments << [:eq, String, '=']

            when :date_period
              arguments << [:gteq, Types::Scalars::Date, '>=']
              arguments << [:lteq, Types::Scalars::Date, '<=']
              arguments << [:between, [Types::Scalars::Date], '><']

            when :boolean
              arguments << [:eq, GraphQL::Types::Boolean, '=']

            when :integer
              arguments << [:eq, GraphQL::Types::Int, '=']
              arguments << [:gteq, GraphQL::Types::Int, '>=']
              arguments << [:lteq, GraphQL::Types::Int, '<=']

            when :float, :currency
              arguments << [:eq, GraphQL::Types::Float, '=']
              arguments << [:gteq, GraphQL::Types::Float, '>=']
              arguments << [:lteq, GraphQL::Types::Float, '<=']
            end

            if arguments.any?
              create_filter_input(filter_name, filter_options) do |input|
                arguments.each do |(name, type, operator)|
                  input.argument name, type, operator_name(operator), required: false
                end
              end
            end
          end

      end

    end
  end
end

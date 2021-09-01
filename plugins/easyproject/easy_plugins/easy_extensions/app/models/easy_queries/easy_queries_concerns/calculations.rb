module EasyQueriesConcerns
  ##
  # EasyQueriesConcerns::Calculations
  #
  # {#aggregate_by} method is not implemented here because of patching.
  # This module would have to be prepended but if somebody use combination
  # include and alias_method_chain it could crash.
  #
  module Calculations

    # See also {#perform_calculation_for_distinct_columns}
    ALLOWED_OPERATIONS = [:sum, :average, :maximum, :minimum]

    # The method is experimental. Use it at your own risk.
    # Calculation is using the same logic and definitions as sumable_sql
    #
    # Inspired by {#entity_sum}
    #
    # You can also defined custom calculations. Usage could change anytime
    # so be prepared for changes :-)
    #
    #     # Imagine and dataset which is calculated as column1/column2
    #     # If you calulcate sum over more records you still need SUM(column1) / SUM(column2)
    #
    #     add_available_column :value,
    #                          sumable_options: {
    #                            custom_sql: {
    #                              sum: 'SUM(column1) / SUM(column2)'
    #                            }
    #                          }
    #
    #     query.entity_sum(:value)
    #     # => SELECT SUM(value) FROM table
    #
    #     query.entities_sum(:value)
    #     # => SELECT SUM(column1) / SUM(column2) FROM table
    #
    #     query.entities_average(:value)
    #     # => SELECT AVG(value) FROM table
    #
    #
    # @param operation [Symbol] Operation could be one of {ALLOWED_OPERATIONS}
    # @param column [Symbol, String, EasyEntityAttribute] Query column or custom SQL
    # @param options [Hash]
    # @option options [String] :group Groups
    # @option options [String] :joins Joins
    #
    # @example Sum by column hours
    #   query.entities_sum(:hours)
    #
    # @example Average by column hours
    #   query.entities_average(:hours)
    #
    # @example Custom sum
    #   query.entities_sum("hours * 3")
    #
    # @example Average by project groups
    #   query.entities_average(:hours, group: ['project_id'])
    #
    # @example Sum by column hours
    #   query.entities_sum(:hours)
    #
    def entities_calculation(operation, column, **options)
      if !ALLOWED_OPERATIONS.include?(operation)
        raise "Unknown operation '#{operation}'. Allowed: #{ALLOWED_OPERATIONS.join(', ')}."
      end

      case column
      when Symbol
        column = columns.find { |c| c.name == column }
      when EasyEntityAttribute
        # Nothing todo
      when String
        return perform_calculation(operation, column, options)
      else
        raise NotImplementedError
      end

      if column.nil?
        raise ArgumentError, 'No column found'
      end

      # Is this code needed?
      #
      # if column.sumable_sql == false
      #   if options[:entities]
      #     # some future code
      #   elsif column.visible? && options[:group]
      #     # some future code
      #   end
      # end

      additional_joins = column.additional_joins(entity, :array)
      additional_joins.concat(joins_for_order_statement(options[:group].to_s, :array, false))

      if grouped?
        additional_joins.concat(group_by_column.additional_joins(entity, :array, false))
      end

      options[:joins] = Array(options[:joins]) + additional_joins
      options[:joins].uniq!

      if column.includes.is_a?(Array) || column.includes.is_a?(Symbol)
        options[:includes] = Array(options[:includes]) + Array(column.includes)
        options[:includes].uniq!
      end

      column_name = column.sumable_sql || column.name

      if column.sumable_options.custom_sql.has_key?(operation)
        perform_calculation_for_custom(column.sumable_options.custom_sql[operation], options)
      elsif column.sumable_options.distinct_columns?
        perform_calculation_for_distinct_columns(operation, column, column_name, options)
      else
        perform_calculation(operation, column_name, options)
      end
    end

    def entities_sum(column, **options)
      entities_calculation(:sum, column, options)
    end

    def entities_average(column, **options)
      entities_calculation(:average, column, options)
    end

    def entities_maximum(column, **options)
      entities_calculation(:maximum, column, options)
    end

    def entities_minimum(column, **options)
      entities_calculation(:minimum, column, options)
    end

    def enabled_aggregations
      ['sum', 'average'].freeze
    end

    private

    def perform_calculation(operation, column_name, options)
      scope = merge_scope(new_entity_scope, options)
      scope = limit_group_ids(scope, options)
      scope.send(operation, column_name)
    end

    def perform_calculation_for_custom(sql, options)
      scope = merge_scope(new_entity_scope, options);
      scope = limit_group_ids(scope, options);

      if options[:group]
        result = scope.pluck(*options[:group], sql)

        if options[:group].size == 1
          result.map { |key, value| [key, value.to_f] }.to_h
        else
          result.map { |*keys, value| [keys, value.to_f] }.to_h
        end
      else
        scope.pluck(sql).first.to_f
      end
    end

    def perform_calculation_for_distinct_columns(operation, column, column_name, options)
      select_group  = []
      group_aliases = []
      select_scope  = entity_scope.all

      options[:group] = Array(options[:group])
      options[:group].each do |group|
        group_alias = select_scope.send(:column_alias_for, group)
        group_aliases << group_alias
        select_group << Arel.sql(group).as(group_alias)
      end

      # Distinct columns must go into GROUP BY but not into SELECT
      column.sumable_options.distinct_columns.each do |distinct_column|
        if distinct_column.include?('.')
          options[:group] << distinct_column
        else
          options[:group] << "#{entity.quoted_table_name}.#{distinct_column}"
        end
      end

      scope = merge_scope(new_entity_scope, options)
      scope = scope.select(Arel.sql(column_name.to_s).maximum.as('result'))

      if select_group.any?
        scope = scope.select(select_group)
      end

      scope = limit_group_ids(scope, options)

      calculation_scope = Arel.sql('(' + scope_for_calculations(scope).to_sql + ')').as('DT1')
      ensure_group_arg  = group_aliases.presence || [nil]

      result_sql = Arel.sql('result')
      result_sql = case operation
                   when :sum then
                     result_sql.sum
                   when :average then
                     result_sql.average
                   when :maximum then
                     result_sql.maximum
                   when :minimum then
                     result_sql.minimum
                   else
                     raise ArgumentError, "Pperation '#{operation}' is not supported"
                   end
      result_sql = result_sql.as('result')

      db_result = entity.base_class.from(calculation_scope).
          group(*ensure_group_arg).
          pluck(*group_aliases, Arel.sql(result_sql.to_sql))

      if select_group.empty?
        result = db_result.first || 0.0
        # fix approximation errors on mysql
        result = result.round(2) if result.is_a?(Float)
      else
        result       = {}
        groups_count = group_aliases.count

        if Redmine::Database.mysql?
          boolean_keys    = entity.columns_hash.select { |_, column_options| column_options.type == :boolean }.keys
          boolean_indexes = []
          options[:group].each_with_index do |group, i|
            if boolean_keys.detect { |key| group.include?(key) }
              boolean_indexes << i
            end
          end
        end

        db_result.each do |row|
          keys = row.first(groups_count)

          if boolean_indexes
            boolean_indexes.each do |index|
              keys[index] = keys[index].to_s.to_boolean
            end
          end

          keys         = keys.first unless groups_count > 1
          result[keys] = row.last || 0.0
          # fix approximation errors on mysql
          result[keys] = result[keys].round(2) if result[keys].is_a?(Float)
        end
      end

      result
    end

  end
end

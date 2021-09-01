module EasyExtensions
  module EasyQueryExtensions
    module Groupable
      class GroupByColumns < EasyEntityAttribute
        include ::Enumerable

        attr_accessor :query

        def initialize(query, columns)
          self.query = query
          @columns   = columns.compact
          super(self.name)
        end

        def each(&block)
          @columns.each(&block)
        end

        def name
          @columns.collect { |c| c.name.to_s }.join('_')
        end

        def single?
          @columns.length == 1
        end

        def group_additional_options
          res = {}
          @columns.each do |col|
            next unless col.polymorphic?
            res[:where] ||= []
            res[:where] << "#{query.entity.table_name}.#{col.polymorphic[:name]}_type = '#{col.polymorphic[:type]}'"
          end
          res[:where] = res[:where].join(' AND ') if res[:where]
          res
        end

        def group_by_statements
          statements = []
          @columns.each do |group_col|
            statements << group_col.group_by_statement(query)
          end
          statements
        end

        def group_by_statement
          group_by_statements.join(', ')
        end

        def additional_group_by_for_sort
          statements = []
          @columns.each do |group_col|
            stm = group_col.additional_group_by_for_sort(query)
            statements << stm if stm.present?
          end
          if statements.any?
            ', ' + statements.join(', ')
          else
            ''
          end
        end

        def group_by_sort_order(query)
          column_sorts = @columns.collect { |column| column.group_by_sort_order(query, query.group_order_for(column.name)) }
          sorts        = []
          if query.group_sort_after
            sorts.concat(column_sorts[0..query.group_sort_after])
            column_sorts = column_sorts[(query.group_sort_after + 1)..-1]
          end
          sort_cols = query.available_columns.select { |c| query.group_sort.key?(c.name.to_s) } if query.group_sort.any?
          query.group_sort.each do |col_name, operation|
            col   = sort_cols.detect { |c| c.name.to_s == col_name }
            order = query.group_order_for(col_name) || col.default_order
            op    = operation.is_a?(Array) ? operation.first : operation
            sorts << "#{op}( #{col.sortable} ) #{order}"
          end
          sorts.concat(column_sorts).flatten.compact #.map{|o| Arel.sql(o)}
        end

        def custom?
          @columns.any? { |c| c.is_a?(EasyQueryCustomFieldColumn) }
        end

        def date?
          @columns.any? { |c| c.date? }
        end

        def date_time?
          @columns.any? { |c| c.date_time? }
        end

        def custom_fields_visibility_by_project_condition
          conditions = []
          @columns.each do |col|
            conditions << col.custom_field.visibility_by_project_condition if col.is_a?(EasyQueryCustomFieldColumn)
          end
          return conditions
        end

        %w(includes references joins preload).each do |meth|
          define_method(meth) do
            res = []
            @columns.each { |c| res.concat(Array.wrap(c.send(meth))) if c.send(meth) }
            res
          end
        end

        def additional_joins(entity_class, type = :array, uniq = true)
          res = []
          @columns.each { |c| res.concat(Array.wrap(c.additional_joins(entity_class, type, uniq))) }
          res
        end

        def value(entity, options = {})
          vals = []
          @columns.each_with_index do |c, i|
            vals << if c.is_a?(EasyQueryCustomFieldColumn) && c.custom_field.multiple? && options[:group]
                      options[:group][i]
                    elsif c.is_a?(EasyQueryColumn) && c.assoc_column? && c.assoc_type == :has_many && c.short_name && options[:group]
                      assoc_vals   = entity.send(c.assoc)
                      value_entity = assoc_vals.detect { |v| v.id == options[:group][i] }
                      value_entity.nested_send(c.short_name) if value_entity
                    else
                      c.value(entity, options)
                    end
          end
          single? ? vals.first : vals
        end

        def sanitize_name(name)
          res = []
          @columns.each_with_index do |c, i|
            val = name.is_a?(Array) ? name[i] : name
            res << (c.is_a?(EasyQueryCustomFieldColumn) ? val.to_param : val)
          end
          single? ? res.first : res
        end
      end

      def group_order_for(column_name)
        if group_sort[column_name].is_a?(Array)
          group_sort[column_name].second || sort_criteria_order_for(column_name)
        else
          sort_criteria_order_for(column_name)
        end
      end

      # column_name => operation|[operation, order]
      def group_sort
        @group_sort_operation ||= {}
      end

      # group column sort idx, used before sorting by additional group sort
      attr_accessor :group_sort_after

      def group_filters
        @group_filters ||= {}
      end

      def having_filter?(field)
        available_filters.key?(field) && [:float, :integer, :currency].include?(available_filters[field][:type])
      end

      def add_group_count_filter(values)
        values ||= []
        if values.is_a?(String)
          values = Array(values.force_encoding('UTF-8'))
        elsif values.is_a?(Array)
          values = values.flatten.collect { |x| x.force_encoding('UTF-8') if x.present? }.compact
        end
        @group_filters[:count] = { values: values }
      end

      def add_group_filter(field, operator, values, operation = :sum)
        return if !having_filter?(field)
        add_filter(field, operator, values, group_filters)
        group_filters[field][:operation] = operation
      end

      # Returns the SQL sort order that should be prepended for grouping
      def group_by_sort_order
        group_by_column.group_by_sort_order(self) if self.grouped?
      end

      def group_by_column
        group_cols = Array(self.group_by).collect { |grp_by| self.groupable_columns.detect { |c| grp_by == c.name.to_s } }.compact
        GroupByColumns.new(self, group_cols) if group_cols.any?
      end

      # Returns true if the query is a grouped query
      def grouped?
        !self.group_by_column.nil?
      end

      def group_additional_options
        return {} unless group_by_column
        group_by_column.group_additional_options
      end

      def group_by_statements
        group_by_column.group_by_statements if group_by_column
      end

      def group_by_statement
        group_by_column.group_by_statement if group_by_column
      end

      def additional_group_by_for_sort
        group_by_column.additional_group_by_for_sort
      end

    end
  end
end

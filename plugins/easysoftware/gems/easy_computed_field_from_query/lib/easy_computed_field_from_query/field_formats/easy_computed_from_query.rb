module EasyComputedCustomFields
  module FieldFormats

    class EasyComputedFromQuery < Redmine::FieldFormat::StringFormat
      include EasyExtensions::EasyAttributeFormatter

      add 'easy_computed_from_query'

      attr_accessor :period

      self.multiple_supported = false
      self.form_partial = 'custom_fields/formats/easy_computed_from_query'

      def self.customized_class_names
        allowed = []
        allowed << 'EasyContact' if Redmine::Plugin.installed?(:easy_contacts)
        allowed
      end

      def date?(custom_field)
        original_format(custom_field).date?(custom_field)
      end

      def label
        :label_easy_computed_from_query
      end

      def available_formulas(custom_field, query)
        %w(sum join min max first last count bool_sum bool_count)
      end

      def display_column_selection?(custom_field)
        %w(sum join min max first last bool_sum).include?(custom_field.settings['easy_query_formula'])
      end

      def before_custom_field_save(custom_field)
        super

        custom_field.editable = false

        query = custom_field.create_easy_query
        query_column = query.get_column(custom_field.settings['easy_query_column']) if query

        if query_column && query_column.is_a?(EasyQueryCustomFieldColumn) && (original_custom_field = query_column.custom_field)
          custom_field.possible_values = original_custom_field.possible_values
          custom_field.multiple = original_custom_field.multiple

          case custom_field.settings['easy_query_formula']
          when 'bool_sum', 'bool_count'
            custom_field.settings['easy_computed_from_query_format'] = 'bool'
          end

          custom_field.settings['easy_computed_from_query_format'] ||= original_custom_field.field_format
        elsif query_column && query_column.is_a?(EasyQueryColumn)
          case custom_field.settings['easy_query_formula']
          when 'sum'
            custom_field.settings['easy_computed_from_query_format'] = 'float'
          when 'join'
            custom_field.settings['easy_computed_from_query_format'] = 'list'
          when 'count'
            custom_field.settings['easy_computed_from_query_format'] = 'int'
          when 'bool_sum', 'bool_count'
            custom_field.settings['easy_computed_from_query_format'] = 'bool'
          when 'max', 'min', 'first', 'last'
            if query_column.date?
              custom_field.settings['easy_computed_from_query_format'] = 'date'
            elsif query_column.numeric?
              custom_field.settings['easy_computed_from_query_format'] = 'float'
            end
            # todo native fields
          end
        elsif custom_field.settings['easy_query_formula'] == 'count'
          custom_field.settings['easy_computed_from_query_format'] = 'int'
        elsif custom_field.settings['easy_query_formula'] == 'bool_count'
          custom_field.settings['easy_computed_from_query_format'] = 'bool'
        end

        custom_field.settings['easy_computed_from_query_format'] ||= 'string'
      end

      def available_columns(custom_field, query)
        basic_columns = query.available_columns.select { |c| !c.name.to_s.include?('.') }

        case custom_field.settings['easy_query_formula']
        when 'sum', 'bool_sum'
          basic_columns.select { |c| c.sumable_top? || c.sumable_bottom? }
        when 'join'
          basic_columns.select { |c| c.is_a?(EasyQueryCustomFieldColumn) && c.custom_field.format.is_a?(Redmine::FieldFormat::ListFormat) }
        when 'min', 'max'
          basic_columns
        when 'first', 'last', 'count', 'bool_count'
          basic_columns
        else
          []
        end
      end

      def cast_single_value(custom_field, value, customized = nil)
        original_format(custom_field).cast_single_value(custom_field, value, customized)
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        original_format(custom_field).formatted_value(view, custom_field, value, customized, html)
      end

      def query_filter_options(custom_field, query)
        original_format(custom_field).query_filter_options(custom_field, query)
      end

      def compute_value_from_query(custom_field, entity, query, currency = nil)
        return nil if custom_field.settings['easy_query_formula'].blank?

        column = query.get_column(custom_field.settings['easy_query_column'])

        query.column_names = [column.name] if column

        filter_name = custom_field.settings['easy_query_entity_filter'].presence || "#{entity.class.table_name}.id"
        if query.add_filter(filter_name, '=', entity.id.to_s).nil?
          if entity.class.name == query.entity.name
            query.add_additional_scope(:id => entity.id)
          else
            Rails.logger.error "CF: ##{custom_field.id} #{custom_field.name}, Filter #{query.class.name}##{entity.class.table_name}.id is not applied! Query return all entities and kill the server."
            return nil
          end
        end

        if column
          if column.is_a?(EasyQueryCurrencyColumn)
            query.easy_currency_code = currency
            column.query = query
          end

          case custom_field.settings['easy_query_formula']
          when 'sum'
            query.entity_sum(column)
          when 'bool_sum'
            query.entity_sum(column) > 0 ? '1' : '0'
          when 'join'
            query.entities.collect { |e| query_column_value(column, e) }.flatten.uniq.compact
          when 'max'
            query.entities.collect { |e| query_column_value(column, e) }.flatten.compact.max
          when 'min'
            query.entities.collect { |e| query_column_value(column, e) }.flatten.compact.min
          when 'last'
            query.entities.collect { |e| query_column_value(column, e) }.flatten.compact.last
          when 'first'
            query.entities.collect { |e| query_column_value(column, e) }.flatten.compact.first
          else
            nil
          end
        else
          case custom_field.settings['easy_query_formula']
          when 'count'
            query.entity_count
          when 'bool_count'
            query.entity_count > 0 ? '1' : '0'
          else
            nil
          end
        end
      end

      protected

      def original_format(custom_field)
        original_format = custom_field.settings['easy_computed_from_query_format']
        original_format = 'string' if original_format.to_s == 'easy_computed_from_query'
        Redmine::FieldFormat.find(original_format)
      end

      # Return value of selected column from source EasyQuery
      # @example Contact CF should be calculated from CRM query column +name+ = name is the column and entity is CRM case
      #
      # @param [EasyQueryColumn] column of source EasyQuery for calculation
      # @param [ActiveRecord] entity from this query
      def query_column_value(column, entity)
        case (value = column.value(entity))
        when FalseClass
          "0"
        when TrueClass # @see lib/redmine/field_format.rb:693
          "1"
        else
          return nil if value.nil? || value.try(:empty?)

          value
        end
      end

    end
  end
end

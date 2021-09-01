module EasyExtensions
  module EasyQueryOutputs
    class ReportOutput < EasyExtensions::EasyQueryHelpers::EasyQueryOutput

      def self.available_for?(query)
        query.groupable_columns.count > 2 && query.sumable_columns? && query.report_support?
      end

      def order
        100
      end

      def before_render
        @grouped_by        = query.group_by
        @columns_was       = query.column_names
        query.group_by     = report_group_by
        query.column_names = Array.wrap(query.settings['report_sum_column'])
      end

      def after_render
        query.group_by     = @grouped_by
        query.column_names = @columns_was
      end

      def report_values
        @report_values ||= query.groups
      end

      def report_group_by
        @report_group_by ||= if query.settings['report_group_by'].is_a?(Array) && query.settings['report_group_by'].count > 1
                               res = query.settings['report_group_by'].dup
                               res << res.shift
                             else
                               query.settings['report_group_by'] || []
                             end
      end

      def top_report_group_by
        extract_top_group(report_group_by)
      end

      def left_report_group_by
        extract_left_group(report_group_by)
      end

      def sum_column
        @sum_column ||= begin
          values = Array.wrap(query.settings['report_sum_column'])
          ary    = []; summable_cols = query.sumable_columns

          values.each do |val|
            col = summable_cols.detect { |col| col.name.to_s == val }
            ary << col if col
          end
          ary << nil if values.include?('')
          ary
        end
      end

      def fixed_value_column_indexes
        return [] unless query.settings['report_group_by'].drop(1).include?('project')
        @fixed_value_column_indexes ||= begin
          col_indexes = []
          sum_column.each_with_index do |col, idx|
            col_indexes << idx if col && col.assoc == :project
          end
          col_indexes
        end
      end

      def group_columns
        @group_columns ||= query.groupable_columns.select { |col| query.group_by.include?(col.name.to_s) }.sort_by { |col| query.group_by.index(col.name.to_s) }
      end

      def group_filters
        @group_filters ||= query.group_by.collect do |cn|
          if query.available_filters[cn]
            cn
          elsif query.available_filters[cn + '_id']
            cn + '_id'
          elsif query.available_filters['x' + cn + '_id']
            'x' + cn + '_id'
          end
        end
      end

      def all_group_filters?
        !group_filters.include?(nil)
      end

      def sort_top_line(line_arr)
        if query.columns_with_position.include?(top_report_group_by)
          group_by_column_name = query.group_by_column.to_a.last.name
          group_by_class       = query.entity.reflect_on_association(group_by_column_name)&.klass
          group_by_class ||= top_report_group_by.classify.constantize rescue nil

          if group_by_class
            return group_by_class.where(id: line_arr).reorder('position').pluck(:id)
          end
        end

        line_arr.sort { |a, b| a && b ? a <=> b : (a ? -1 : 1) }
      end

      def extract_top_group(group)
        group.last
      end

      def extract_left_group(group)
        group[0..-2]
      end

      def column_group(heading, left_group)
        left_group + [heading]
      end

      def top_line
        @top_line ||= sort_top_line(report_values.keys.collect { |k| extract_top_group(k) }.uniq)
      end

      def top_line_names
        @top_line_names ||= report_values.inject({}) do |res, (k, attrs)|
          res[extract_top_group(k)] ||= extract_top_group(attrs[:name])
          res
        end
      end

      def top_line_entities
        @top_line_entities ||= report_values.inject({}) do |res, (k, attrs)|
          res[extract_top_group(k)] ||= attrs[:entity]
          res
        end
      end

      def groups
        @groups ||= report_values.keys.inject(ActiveSupport::OrderedHash.new) do |memo, key|
          memo[extract_left_group(key)] ||= []
          memo[extract_left_group(key)] << extract_top_group(key)
          memo
        end
      end

      def group_entity(key)
        report_values[key][:entity]
      end

      def group_name(key)
        report_values[key][:name]
      end

      def variables
        super.merge(entities: report_values, bottom_total: bottom_total)
      end

      def column_value(column_group, col_idx = 0)
        sum_column[col_idx] ? report_values[column_group][:sums][:bottom].values[col_idx].to_f : report_values[column_group][:count]
      end

      def format_value(unformatted_value, group = nil, col_idx = 0, options = {})
        if (column = sum_column[col_idx]).present?
          if options[:for_export]
            value = h.format_value_for_export(query.entity, column, unformatted_value)
          else
            value = h.format_html_entity_attribute(query.entity, column, unformatted_value, options)
          end
        else
          value = unformatted_value
        end
        if options[:no_html].nil? && group && all_group_filters?
          filters = {}
          group_filters.each_with_index do |f, i|
            if group[i] == :any
              query.add_filter(f, '*', nil, filters)
            elsif group[i].nil?
              query.add_filter(f, '!*', nil, filters)
            else
              case query.type_for(f)
              when :date_period
                date = group[i].to_date rescue nil
                query.add_filter(f, 'date_period_2', { from: date, to: query.end_of_period_zoom(date) }, filters)
              else
                query.add_filter(f, '=', group[i].to_s, filters)
              end
            end
          end
          query_params = query.to_params
          filters.each do |f, o|
            query_params[:fields]       |= [f]
            query_params[:operators][f] = o[:operator]
            query_params[:values][f]    = o[:values]
          end
          query_params[:column_names] = query.default_list_columns + (group_columns.collect { |c| c.name.to_s })
          query_params[:column_names] << sum_column[col_idx].name.to_s if sum_column[col_idx]
          query_params[:show_sum_row] = '1'
          query_params[:group_by]     = nil
          query_params[:outputs]      = ['list']
          query_path                  = query.entity_easy_query_path(query_params)
          query_path ? h.link_to(value, query_path) : value
        else
          value
        end
      end

      def format_group(index, unformatted_value, entity = nil, for_export = false)
        if unformatted_value.present?
          column = group_columns[index]
          if for_export
            h.format_value_for_export(entity || query.entity, column, unformatted_value)
          else
            h.format_html_entity_attribute(query.entity, column, unformatted_value, period: query.group_by_period, entity: entity)
          end
        else
          '[' + h.l(:label_none) + ']'
        end
      end

      def render_data
        render_callback do
          if !query.grouped? || query.group_by_column.count < 2
            h.content_tag(:p, h.l(:label_no_data), class: 'nodata')
          elsif !groups.any?
            h.content_tag(:p, h.l(:label_no_data), class: 'nodata')
          else
            h.render partial: 'easy_queries/easy_query_report', locals: variables
          end
        end
      end

      def bottom_total
        bottom_total = { label: Array(h.l(:label_total)) }
        top_line.each { |heading_group| bottom_total[heading_group] = [0] * sum_column.count }
        bottom_total[:total] = [0] * sum_column.count
        bottom_total
      end

    end
  end
end

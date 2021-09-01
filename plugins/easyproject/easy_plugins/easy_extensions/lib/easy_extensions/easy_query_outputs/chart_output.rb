module EasyExtensions
  module EasyQueryOutputs
    ##
    # EasyExtensions::EasyQueryOutputs::ChartOutput
    #
    # == Aggregation:
    # see {#EasyQueriesConcerns::Calculations}
    #
    # "sum" does not necessarily mean sum
    # Its common word for aggregations
    #
    # == Long tail:
    # {values_details} exist because we need to track details about dataset
    #
    # You can mix long tail, time series, secondary axis, secondary query
    # aggregation type, grouping, ...
    #
    class ChartOutput < EasyExtensions::EasyQueryHelpers::EasyQueryOutput

      attr_reader :data_names
      attr_reader :entity_names
      attr_reader :values_details

      def self.available_for?(query)
        query.groupable_columns.any? && query.chart_support?
      end

      def self.displays_snapshot?
        true
      end

      CHART_TYPES = %w(pie bar line)

      CHART_TYPES.each do |type|
        define_method("#{type}?") do
          chart_settings['primary_renderer'] == type
        end
      end

      PIE_MAX_VALUES = 20

      def order
        1
      end

      def configured?
        query.grouped?
      end

      def apply_settings
        @params_was                      = {}
        @params_was[:group_by]           = query.group_by
        @params_was[:show_sum_row]       = query.show_sum_row
        @params_was[:load_groups_opened] = query.load_groups_opened
        @params_was[:column_names]       = query.column_names

        query.group_by                  = Array.wrap(chart_settings['axis_x_column']).first
        query.show_sum_row              = '1'
        query.load_groups_opened        = '0'
        query.column_names              = query.default_list_columns + (Array.wrap(chart_settings['axis_y_column']) + Array.wrap(chart_settings['secondary_axis_y_column'].presence).compact)
        chart_settings['period_column'] = Array.wrap(chart_settings['axis_x_column']).first if query.chart_grouped_by_date_column?
      end

      def restore_settings
        @params_was.each do |k, val|
          query.send("#{k}=", val)
        end
      end

      def configure_from_defaults
        return false unless configured?
        chart_settings['axis_x_column'] = query.group_by.first
        if (ycol = query.columns.detect { |col| col.sumable? })
          chart_settings['axis_y_column'] = ycol.name
          chart_settings['axis_y_type']   = 'sum'
        else
          chart_settings['axis_y_type'] = 'count'
        end
        true
      end

      def chart_settings
        query.chart_settings
      end

      def before_render
        super
        unless chart_settings['period_column'].blank?
          filter             = period_filter_name
          @period_filter_was = query.filters.delete(filter)
          query.apply_period_filter(filter)
        end
      end

      def after_render
        super
        filter = period_filter_name
        if @period_filter_was
          query.filters[filter] = @period_filter_was
        else
          query.filters.delete(filter)
        end
      end

      def sum_col
        return nil if chart_settings['axis_y_type'] == 'count'
        @sum_col ||= query.sumable_columns.detect { |c| c.name.to_s == chart_settings['axis_y_column'].to_s }
      end

      def secondary_sum_col
        return nil if chart_settings['primary_renderer'] == 'pie' || chart_settings['secondary_axis_y_column'].blank?
        @secondary_sum_col ||= query.sumable_columns.detect { |c| c.name.to_s == chart_settings['secondary_axis_y_column'].to_s }
      end

      def aggreation_label_of
        aggregation = chart_settings['axis_y_type'] || 'sum'
        h.l("label_#{aggregation}_of", default: ["label_page_module_chart_axis_y_#{aggregation}".to_sym])
      end

      def chart_data
        return @chart_data if @chart_data
        before_render
        query.column_names = [chart_settings['axis_x_column'], chart_settings['axis_y_column'], chart_settings['secondary_axis_y_column'].presence].flatten.compact
        query.aggregate_by = chart_settings['axis_y_type']

        @chart_data     = {}
        @data_names     = {}
        @entity_names   = {}
        @values_details = {}

        groups                 = query.groups
        grouped_by_date_column = query.chart_grouped_by_date_column?

        attr_count = chart_settings['axis_y_type'] == 'count'
        groups.each do |group, attrs|
          group_name                        = grouped_by_date_column ? attrs[:name] : group
          values                            = attr_count ? attrs[:count] : attrs[:sums][:bottom][sum_col]
          @chart_data[group_name]           = { raw_name: group, name: attrs[:name], values: values.to_f.round(2), entity: attrs[:entity] }
          @chart_data[group_name][:values2] = attrs[:sums][:bottom][secondary_sum_col].to_f.round(2) if secondary_sum_col
        end if !groups.blank?

        @values_details[:values] = { aggregate_by: chart_settings['axis_y_type'] }

        if secondary_sum_col
          @values_details[:values2] = { aggregate_by: chart_settings['axis_y_type'] }
        end

        @yaxis_label = chart_settings['y_label'].presence
        if @yaxis_label.nil?
          if attr_count
            @yaxis_label = h.l(:label_page_module_chart_axis_y_count)
          else
            @yaxis_label = aggreation_label_of
            @yaxis_label << ' ' << sum_col.caption if sum_col && sum_col.caption
          end
          @entity_names = { values: query.model.class.translated_name }
        end
        @yaxis2_label         = aggreation_label_of + ' ' + secondary_sum_col.caption if secondary_sum_col && secondary_sum_col.caption
        @data_names           = { values: @yaxis_label }
        @data_names[:values2] = @yaxis2_label if @yaxis2_label

        # fill blank spaces in date groups
        if grouped_by_date_column
          backup      = @chart_data
          @chart_data = {}
          current     = query.beginning_of_period_zoom(query.period_start_date).to_time
          backup.keys.compact.sort.each do |key|
            bound            = query.beginning_of_period_zoom(key.to_time).to_time
            current          = next_tick(current, bound.to_date)
            @chart_data[key] = backup[key]
            current          = query.beginning_of_period_zoom(next_period(query, key)).to_time
          end
          beginning_of_period_zoom = query.beginning_of_period_zoom(query.period_end_date).to_date
          current                  = next_tick(current, beginning_of_period_zoom.to_date, true)

          # Name is still Date or Time object
          @chart_data.each do |_, attrs|
            range            = query.range_of_period_zoom(attrs[:name])
            attrs[:raw_name] = "#{range.begin.to_date}|#{range.end.to_date}"
          end
        end

        if chart_settings['primary_renderer'] == 'bar' && chart_settings['bar_direction'] == 'horizontal'
          @xaxis_label = @yaxis_label
          @yaxis_label = nil
        end

        if chart_settings['additional_queries'].is_a?(Hash)
          chart_settings['additional_queries'].each do |key, query_settings|
            next unless query_settings['easy_query_type'].present?
            q = query_settings['easy_query_type'].constantize.new rescue nil
            next unless q
            q.from_params(query_settings)
            q.project          = query.project
            q.output           = 'chart'
            q.period_settings  = query.period_settings
            other_chart_output = RedmineExtensions::BasePresenter.present(q, h, query.options).outputs.first
            if other_chart_output
              other_chart_output.render_callback do
                add_data = other_chart_output.chart_data
                q_key    = 'additional_' + key.to_s
                add_data.each do |key, val|
                  @chart_data[key]              ||= { name: val[:name] }
                  @chart_data[key][q_key]       = val[:values]
                  @chart_data[key][q_key + '2'] = val[:values2] if val.key?(:values2)
                end
                @entity_names[q_key]   = other_chart_output.entity_names[:values]
                @data_names[q_key]     = other_chart_output.data_names[:values]
                @values_details[q_key] = other_chart_output.values_details[:values]

                if other_chart_output.data_names.key?(:values2)
                  @data_names[q_key + '2']     = other_chart_output.data_names[:values2]
                  @values_details[q_key + '2'] = other_chart_output.values_details[:values2]
                end
              end
              @chart_data = sort_double_line_chart(@chart_data) if chart_settings['primary_renderer'] == 'line'
            end
          end
        end
        @chart_data
      end

      def next_tick(current, bound, include_bound = false)
        tick_index = 0
        operator   = include_bound ? '<=' : '<'
        while current.to_date.send(operator, bound)
          tick_index += 1
          raise 'Chart error! too many periods' if tick_index > 1000
          @chart_data[current]           = { name: current, values: 0 }
          @chart_data[current][:values2] = 0 if secondary_sum_col
          current                        = query.beginning_of_period_zoom(next_period(query, current)).to_time
        end
      end

      def should_sort_bars_by_value?(query)
        chart_settings['primary_renderer'] == 'bar' && !query.chart_grouped_by_date_column? && !chart_settings['bar_sort_by_axis_x'].to_s.to_boolean && !query.sort_criteria_order_for(chart_settings['axis_x_column'])
      end

      def reorder_bar_chart(data)
        data.sort_by! { |d| d[:values].to_f * -1 } if should_sort_bars_by_value?(query)
        data.reverse! if chart_settings['bar_reverse_order'].to_s.to_boolean
        data
      end

      def reorder_pie_chart(data)
        data.sort_by! { |d| -d[:values].to_f }
      end

      def sort_double_line_chart(data)
        sorted_data = data.sort.to_h
        sorted_data.each do |k, v|
          sorted_data[k][:values] = 0 if v[:values].nil?
          sorted_data[k]['additional_0'] = 0 if sorted_data[k]['additional_0'].nil?
        end
        sorted_data
      end

      def calculate_tail_data(remaining_sorted_data, name: :label_long_tail)
        tail_data = { name: h.l(name) }

        values_details.each do |key, details|
          # Just for sure
          if !remaining_sorted_data.first.has_key?(key)
            next
          end

          # For now, every types need a sum
          values_sum = remaining_sorted_data.reduce(0.0) { |sum, d| sum + d[key] }

          case details[:aggregate_by]
          when 'average'
            values = values_sum / remaining_sorted_data.size
          else
            values = values_sum
          end

          tail_data[key] = values.to_f.round(2)
        end

        tail_data
      end

      def render_json_data(api)
        if chart_data
          chart_data.each do |group, datum|
            datum[:name] = h.format_groupby_entity_attribute(query.entity, Array(query.group_by_column), datum[:name], entity: datum.delete(:entity), group: group, period: query.group_by_period, no_html: true).to_s
          end

          sorted_data           = chart_data.values
          sorted_data           = reorder_bar_chart(sorted_data) if bar?
          remaining_sorted_data = []

          if bar? && chart_settings['bar_limit'].present? && chart_settings['bar_limit'].to_i > 0
            bar_limit = chart_settings['bar_limit'].to_i

            # Slice could return a nil
            remaining_sorted_data = Array(sorted_data.slice(bar_limit..-1))
            sorted_data           = sorted_data.first(bar_limit)
          end

          if chart_settings['long_tail'] == '1' && !query.chart_grouped_by_date_column? && !remaining_sorted_data.empty?
            sorted_data << calculate_tail_data(remaining_sorted_data)
          end

          # Pie is useless if there si many values
          if pie?
            sorted_data = reorder_pie_chart(sorted_data)
            if sorted_data.size > PIE_MAX_VALUES
              remaining_sorted_data = Array(sorted_data.slice(PIE_MAX_VALUES..-1))
              sorted_data           = sorted_data.first(PIE_MAX_VALUES)
              sorted_data << calculate_tail_data(remaining_sorted_data, name: :label_others)
            end
          end

          if query.show_sum_row? && (chart_settings['axis_y_type'] == 'count' || chart_settings['axis_y_type'] == 'sum')
            global_sum = Hash.new(0.0)
            sorted_data.each do |datum|
              data_names.each_key { |k| global_sum[k] += datum[k].to_f }
            end

            api.total global_sum
          end

          # cumulative charts | global_sum ^ calculated before
          if ['line', 'bar'].include?(chart_settings['primary_renderer'])
            cumulative_additional_queries = chart_settings[:additional_queries] && chart_settings[:additional_queries].select { |key, value| value["chart_settings"] && value["chart_settings"]["cumulative"] == "1" }.keys
            cumulative_additional_queries.map! { |key| "additional_#{key}" } unless cumulative_additional_queries.blank?
            cumulative_data_names = data_names.keys.select do |key|
              (key.to_s.include?('values') && chart_settings['cumulative'] == "1") ||
                  (cumulative_additional_queries && cumulative_additional_queries.any? { |q| key.to_s.include?(q) })
            end
            sum                   = {}
            cumulative_data_names.map { |key| sum[key] = 0.0 }
            sorted_data.each do |datum|
              cumulative_data_names.each do |k|
                datum[k] = sum[k] += datum[k].to_f
              end
            end
          end

          # I have no idea why pie chart use `columns` instead of `json`
          # but I need full-data even for them.
          api.all_data sorted_data

          ticks = sorted_data.map { |d| d[:name] }
          api.ticks ticks
          api.data do
            if pie?
              unique_names!(ticks)

              api.array :columns do
                sorted_data.each_with_index do |d, i|
                  api.value [ticks[i], d[:values].to_f]
                end
              end
            else
              api.json sorted_data
              api.keys do
                api.value data_names.keys
              end
            end

            api.names data_names
            api.entity_names entity_names
            api.type chart_settings['primary_renderer']
          end
        end

        api.chart_options do

          if chart_settings['primary_renderer'] == 'pie'
            insets    = { 'nw' => 'top-left', 'ne' => 'top-right' }
            locations = { 's' => 'bottom', 'e' => 'right' }
            location  = chart_settings['legend']['location'] if chart_settings['legend']
            api.legend do
              if chart_settings['legend_enabled'] == '1'
                api.show true
                api.position insets.key?(location) ? 'inset' : locations[location]
                api.inset do
                  api.anchor insets[location]
                end
              else
                api.hide true
              end
            end
          else
            api.axis do
              api.rotated chart_settings['primary_renderer'] == 'bar' && chart_settings['bar_direction'] == 'horizontal'
              api.x do
                api.label @xaxis_label
              end
              api.y do
                api.label @yaxis_label

                api.padding do
                  api.bottom 0
                end
              end
            end
          end

          # api.highlighter({'show' => true, 'tooltipAxes' => 'both', 'useAxesFormatters' => false, 'formatString' => '%s: %s', 'tooltipFormatString' => '%s: %s'})
        end
        if sum_col && sum_col.is_a?(EasyQueryCurrencyColumn) && query.easy_currency_code
          api.formats do
            api.delimiter h.t('number.currency.format.delimiter').presence || ' '
            api.separator h.t('number.currency.format.separator')
            api.y_axis 'currency'
            api.labels 'currency'
          end
          api.array :currency do
            api.prefix ''
            api.suffix EasyCurrency.get_symbol(query.easy_currency_code)
          end
        else
          api.formats do
            api.delimiter h.t('number.format.delimiter').presence || ' '
            api.separator h.t('number.format.separator')
          end
        end
      end


      # render helpers
      def has_period_filter?
        !period_column.nil?
      end

      def period_column
        return if query.chart_settings['period_column'].blank?
        @period_column ||= query.get_column(query.chart_settings['period_column'])
      end

      def period_filter_name
        (period_column.try(:filter) || query.chart_settings['period_column']).to_s
      end

      def next_period(query, previous)
        previous = previous.to_date
        case query.period_zoom.to_s
        when 'day'
          previous.next_day
        when 'week'
          previous.next_week(EasyUtils::DateUtils.day_of_week_start)
        when 'month'
          previous.next_month.beginning_of_month
        when 'quarter'
          previous.next_quarter.beginning_of_month
        when 'year'
          previous.next_year.beginning_of_year
        end
      end

      def unique_names!(ticks)
        ticks.find_all { |e| ticks.rindex(e) != ticks.index(e) }.uniq.each do |duplicity|
          i = 0
          ticks.map! do |tick|
            if duplicity == tick
              s = "#{tick}#{' ' * i}"
              i += 1
              s
            else
              tick
            end
          end
        end
      end

    end
  end
end

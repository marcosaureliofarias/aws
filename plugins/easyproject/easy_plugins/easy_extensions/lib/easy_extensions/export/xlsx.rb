require 'rubyXL'

module EasyExtensions
  module Export
    class Xlsx
      include ProjectsHelper
      include EasyQueryHelper
      include CustomFieldsHelper
      include EasyExtensions::Export::ExportHelper

      FIRST_OUTPUT_ROW  = 3
      FIRST_OUTPUT_CELL = 0

      COLUMN_WIDTH_ADDITION = 3

      TITLE_FONT_SIZE = 20

      BORDER_STYLE = 'thin'

      DATE_TIME_FIELDS = %w(DateTime Time).to_set
      DATE_FIELDS      = ['Date'].to_set + DATE_TIME_FIELDS

      # Logo
      #LOGO_X = 220
      #LOGO_Y = 16.5
      #LOGO_WIDTH  = 0
      #LOGO_HEIGHT = 7

      def initialize(entities, query, options = {})
        @entities = entities
        @query    = query
        @options  = options

        @current_row = @options[:without_title] ? 0 : self.class::FIRST_OUTPUT_ROW

        @name      = title_and_name
        @col_width = []

        @book = RubyXL::Workbook.new

        @columns = @query.inline_columns
        if @query.has_column?(:description) && !@columns.any? { |c| c.name == :description }
          @columns.concat([@query.columns.detect { |c| c.name == :description }])
        end
        create
      end

      def output
        @book.worksheets.each { |ws| ws.sheet_name = ws.sheet_name.tr('/\*[]:?', ' ') }
        @book.stream.string
      end

      private

      def create
        make_title unless @options[:without_title]

        render_header
        render_records
        set_column_widths
      end

      def set_column_widths
        @col_width.each_with_index do |width, index|
          @book[0].change_column_width(index, width + COLUMN_WIDTH_ADDITION)
        end
      end

      def update_max_column_width(column, width)
        @col_width[column] = width if !@col_width[column] || width > @col_width[column]
      end

      def render_records
        @book.add_worksheet
        @book[0].sheet_name = @name

        @current_row        += 1 if @query.period_columns?
        @entities.each do |group, attributes|
          if @query.open_category?(group)

            # Group header
            if @query.grouped?
              render_group(@current_row, group, attributes)
              @current_row += 1
            end

            # Entities
            easy_query_entity_list(attributes[:entities]) do |entity, level|
              values = row_values(entity, level)

              render_and_increment_current_row(values, false)
            end
            render_group_sum(@current_row, group, attributes)

            @current_row += 2
          end
        end
        render_final_sum(@current_row)
      end

      def make_title
        #render_logo
        cell = get_cell(0, 0, @name)
        cell.change_font_bold(true)
        cell.change_font_size(TITLE_FONT_SIZE)
      end

      def render_header
        if @query.period_columns?
          period_row = [''] * @query.non_period_inline_columns.length
          column_row = @query.non_period_inline_columns
          0.upto(@query.number_of_periods_by_zoom - 1) do |idx|
            period_row << query_period_name(@query, idx)
            period_row += [''] * (@query.period_columns.length - 1)
            column_row += @query.period_columns
          end
          render_and_increment_current_row(period_row, false)
          render_and_increment_current_row(column_row, true)
        else
          render_and_increment_current_row(@columns, true)
        end
      end

      def format_xlsx_value(entity, column, unformatted_value = nil)
        unformatted_value = unformatted_value || column.value(entity)
        if column.name.to_s.include?('status_time')
          value = (unformatted_value.to_f / 1.minute.to_f).round(2)
        elsif ['status', 'easy_online_status', 'open_duration_in_hours', 'approval_status', 'previous_approval_status'].include?(column.name.to_s)
          value = format_value_for_export(entity, column)
        elsif unformatted_value.is_a?(Integer)
          value = unformatted_value
        elsif column.numeric? || unformatted_value.is_a?(Numeric)
          # to_f, because it returns string
          value = unformatted_value.to_f
        elsif column.date?
          value = unformatted_value
        else
          value = format_value_for_export(entity, column)
        end
        value
      end

      def row_values(entity, level)
        values           = []
        columns_to_print = @columns
        columns_to_print.each do |column|
          value = format_xlsx_value(entity, column)

          # level can be nil
          if [:name, :subject].include?(column.name)
            value = ('  ' * level.to_i) + value
          elsif value.class.name.in?(DATE_TIME_FIELDS)
            value = User.current.user_time_in_zone(value)
            value = value.to_datetime if value.is_a?(Time)

            value = value.change(:offset => "+0000") # show values in Excel in user's timezone instead of UTC
          end

          values << value
        end
        values
      end

      def render_group(row, group, attributes)
        value = format_value_for_export(@query.entity, @query.group_by_column, attributes[:name])
        if @query.count_on_different_column == nil
          value << " (#{easy_query_group_by_title_tags(@query, attributes[:count], attributes[:percent], attributes[:sums], { :plain => true })})" unless @options[:hide_sums_in_group_by]
          cell = get_cell(row, FIRST_OUTPUT_CELL, value)
          cell.change_font_bold(true)
          render_border_row(row, 'medium')
        else
          [value, attributes[:count]].each_with_index do |value, i|
            cell = get_cell(row, FIRST_OUTPUT_CELL + i, value)
            cell.change_font_bold(true)
            update_max_column_width(i, value.to_s.length)
            render_border_cell(row, FIRST_OUTPUT_CELL + i)
          end
        end

      end

      def get_cell(row, column, content = '')
        cell = @book.worksheets[0].sheet_data[row][column] if !@book.worksheets[0].sheet_data[row].nil?
        if cell.nil?
          cell = @book[0].add_cell(row, column)
          if content.class.name.in?(DATE_FIELDS)
            cell.set_number_format(xlsx_datetime_format(content))
          elsif content.is_a?(Numeric)
            if content.is_a?(Float)
              format_cell_number(cell, :float)
            else
              format_cell_number(cell, :integer)
            end
          end
          cell.change_contents(content)
        end
        cell
      end

      def render_border_cell(row, column, border_style = BORDER_STYLE)
        cell = get_cell(row, column)
        cell.change_border(:left, border_style)
        cell.change_border(:right, border_style)
        cell.change_border(:top, border_style)
        cell.change_border(:bottom, border_style)
      end

      def render_border_row(row, border_style = BORDER_STYLE)
        columns_to_print = @columns
        columns_to_print.count.times do |index|
          i    = FIRST_OUTPUT_CELL + index
          cell = get_cell(row, i)
          if i == 0
            cell.change_border(:left, border_style)
          elsif i == columns_to_print.count - 1
            cell.change_border(:right, border_style)
          end
          cell.change_border(:top, border_style)
          cell.change_border(:bottom, border_style)
        end
      end

      def render_row(row, values, head = false)
        values.each_with_index do |column, i|
          if head
            cell = get_cell(row, FIRST_OUTPUT_CELL + i, column.caption.to_s)
            if theme
              cell.change_font_color(fix_hex_color(theme.header_font_hex_color))
              cell.change_fill(fix_hex_color(theme.header_hex_color))
            end
            cell.change_font_bold(true)
            update_max_column_width(i, column.caption.to_s.length)
          else
            cell = get_cell(row, FIRST_OUTPUT_CELL + i, column)
            update_max_column_width(i, column.to_s.length)
          end
          render_border_cell(row, FIRST_OUTPUT_CELL + i)
        end
      end

      def render_and_increment_current_row(values, head = false)
        render_row(@current_row, values, head)
        @current_row += 1
      end

      def render_group_sum(row, group, attributes)
        return unless @query.grouped?
        return unless sumable?
        columns_to_print = @columns
        columns_to_print.each_with_index do |column, index|
          if column.sumable_bottom?
            value = format_xlsx_value(@query.entity, column, attributes[:sums][:bottom][column]).to_f
          elsif column.sumable? && !column.sumable_sql && column.visible?
            value = format_xlsx_value(@query.entity, column, @query.summarize_column(column, nil, group).to_f)
          else
            value = ''
          end

          get_cell(row, FIRST_OUTPUT_CELL + index, value)
          update_max_column_width(index, value.to_s.length)
        end
        render_border_row(row, 'medium')
      end

      def render_final_sum(row)
        return unless sumable?
        columns_to_print = @columns
        columns_to_print.each_with_index do |column, index|
          if column.sumable_bottom? || (column.sumable? && column.visible?)
            # value = format_value_for_export(@query.entity, column, @entities.values.inject(0){|mem,var| (var[:sums] && var[:sums][:bottom]) ? mem += (var[:sums][:bottom][column] || 0).to_f : nil; mem })
            if column.sumable_sql == false
              @sum_entities ||= @entities.values.flat_map { |e| e[:entities] }
            end
            value = format_xlsx_value(@query.entity, column, @query.entity_sum(column, :entities => @sum_entities)).to_f
          else
            value = (column == @columns.first ? l(:label_total_total) : '')
          end

          get_cell(row, FIRST_OUTPUT_CELL + index, value)
          update_max_column_width(index, value.to_s.length)
        end
        render_border_row(row, 'medium')
      end

      def sumable?
        columns_to_print = @columns
        if columns_to_print.detect { |i| i.sumable? }
          true
        else
          false
        end
      end

      # Title of xlsx and title on the header
      def title_and_name
        name = l(@options[:caption]) if @options[:caption].present?
        name || get_export_filename('', @query, @options[:default_title]).gsub(/\.\Z/, '')
      end

      # Styles
      # -----------------------------------------

      def fix_hex_color(color)
        color[1..-1]
      end

      def set_style_header(column_count)
        if theme
          column_count.times do |i|
            @book.worksheets[0].sheet_data[0][i].change_font_color(fix_hex_color(theme.header_font_hex_color))
            @book.worksheets[0].sheet_data[0][i].change_fill(fix_hex_color(theme.header_hex_color))
          end
        end
      end

      def xlsx_date_format
        format = Setting.date_format.presence || Setting::DATE_FORMATS.first
        format.gsub(/%Y|%m|%d|%b|%B/, '%Y' => 'YYYY', '%m' => 'mm', '%d' => 'dd', '%b' => 'mmm', '%B' => 'mmmm')
      end

      def xlsx_time_format
        format      = Setting.time_format.presence || Setting::TIME_FORMATS.first
        time_format = format.gsub(/%H|%M|%I|%p/, '%H' => 'hh', '%M' => 'mm', '%I' => 'hh', '%p' => 'AM/PM')
        "#{xlsx_date_format} #{time_format}"
      end

      def format_cell_number(cell, format)
        xlsx_format = case format
                      when :integer
                        '0'
                      when :float
                        zeros = '0' * l('number.format.precision').to_i
                        "0.#{zeros}"
                      when :percentage
                        zeros = '0' * l('number.format.precision').to_i
                        "0.#{zeros}%"
                      end
        cell.set_number_format(xlsx_format)
      end

      def xlsx_datetime_format(content)
        if content.class.name.in? DATE_TIME_FIELDS
          xlsx_time_format
        elsif content.is_a?(Date)
          xlsx_date_format
        end
      end

    end
  end
end

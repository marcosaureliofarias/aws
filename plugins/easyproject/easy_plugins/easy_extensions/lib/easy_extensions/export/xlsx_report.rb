require 'rubyXL'

module EasyExtensions
  module Export
    class XlsxReport < Xlsx
      include TimelogHelper

      def initialize(entities, query, options = {})
        @report = entities
        super(entities, query, options)
      end

      private

      def render_records
        @book.add_worksheet
        @book[0].sheet_name = @name

        current_row = FIRST_OUTPUT_ROW + 1

        entities = []
        report_criteria_to_xlsx(entities, @report.available_criteria, @report.columns, @report.criteria, @report.periods, @report.hours)

        entities.each do |row|
          render_row(current_row, row)
          current_row += 1
        end
        current_row += 2

        render_final_sum(current_row)
      end

      def render_header
        headers = @report.criteria.map { |criteria| l_or_humanize(@report.available_criteria[criteria][:label]) }
        headers.concat(@report.periods)
        headers << l(:label_total_time)

        render_row(FIRST_OUTPUT_ROW, headers, true)
      end

      def render_border_row(row, border_style = BORDER_STYLE)
        col_count = (@report.criteria.size + @report.periods.size) + 1
        col_count.times do |index|
          i    = FIRST_OUTPUT_CELL + index
          cell = get_cell(row, i)
          if i == 0
            cell.change_border(:left, border_style)
          elsif i == col_count - 1
            cell.change_border(:right, border_style)
          end
          cell.change_border(:top, border_style)
          cell.change_border(:bottom, border_style)
        end
      end

      def render_row(row, values, head = false)
        values.each_with_index do |column, i|
          if head
            cell = get_cell(row, FIRST_OUTPUT_CELL + i, column.to_s)
            if theme
              cell.change_font_color(fix_hex_color(theme.header_font_hex_color))
              cell.change_fill(fix_hex_color(theme.header_hex_color))
            end
            cell.change_font_bold(true)
            update_max_column_width(i, column.to_s.length)
          else
            cell = get_cell(row, FIRST_OUTPUT_CELL + i, column)
            update_max_column_width(i, column.length)
          end
          render_border_cell(row, FIRST_OUTPUT_CELL + i)
        end
      end

      def render_final_sum(row)
        columns = [l(:label_total_time)] + [''] * (@report.criteria.size - 1)
        total   = 0
        @report.periods.each do |period|
          sum   = sum_hours(select_hours(@report.hours, @report.columns, period.to_s))
          total += sum
          columns << (sum > 0 ? format_locale_number(sum) : '')
        end
        columns << format_locale_number(total)
        columns

        columns.each_with_index do |value, index|
          cell = get_cell(row, FIRST_OUTPUT_CELL + index, value)
          update_max_column_width(index, value.length)
        end
        render_border_row(row, 'medium')
      end

    end
  end
end

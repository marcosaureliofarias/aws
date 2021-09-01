module EasyExtensions
  module Export
    class Pdf
      include EasyExtensions::Export::ExportHelper

      # Landscape A4 = 210 x 297 mm
      PAGE_HEIGHT   = 210
      PAGE_WIDTH    = 297
      LEFT_MARGIN   = 10
      RIGHT_MARGIN  = 10
      BOTTOM_MARGIN = 20
      ROW_HEIGHT    = 5

      # Logo
      LOGO_X      = 220
      LOGO_Y      = 16.5
      LOGO_WIDTH  = 0
      LOGO_HEIGHT = 7

      # Limit
      COLUMN_LIMIT = 20

      def self.helper(*args)
        # do nothing
      end

      def initialize(entities, query, options = {})
        @entities = entities
        @query    = query
        @options  = options

        @name        = @query.class.to_s.tableize
        @col_width   = []
        @table_width = PAGE_WIDTH - RIGHT_MARGIN - LEFT_MARGIN
        @pdf         = ITCPDF.new(current_language, 'L')

        # Description will be rendered on new line
        if @query.has_column?(:description)
          @print_description = true
          @query.column_names.delete(:description)
        end

        @query.column_names = @query.column_names.first(COLUMN_LIMIT)

        @columns = @query.inline_columns

        create
      end

      def output
        @pdf.output
      end

      private

      def create
        prepare_pdf
        make_title

        render_header
        render_records
        render_final_sum
      end

      def render_records
        @entities.each do |group, attributes|
          if @query.open_category?(group)

            # Group header
            if @query.grouped?
              render_group(group, attributes)
            end

            # Entities
            easy_query_entity_list(attributes[:entities]) do |entity, level|
              base_y = @pdf.GetY
              base_x = @pdf.GetX

              values     = row_values(entity, level)
              max_height = get_max_height(values)

              # Make new page if it doesn't fit on the current one
              space_left = PAGE_HEIGHT - BOTTOM_MARGIN - base_y
              if max_height > space_left
                @pdf.AddPage("L")
                @render_new_header = true
              end

              if @render_new_header
                render_header
                base_x             = @pdf.GetX
                base_y             = @pdf.GetY
                @render_new_header = nil
              end

              render_row(values)
              render_borders(base_x, base_y, max_height)

              @pdf.SetY(base_y + max_height)

              if @print_description
                next if entity.description.blank?
                node = Nokogiri::HTML::DocumentFragment.parse(entity.description.to_s)
                node.css('img').each { |img| img.remove }
                description = @pdf.formatted_text(node.to_s)
                height = @pdf.get_string_height(@table_width, description)
                space_left = PAGE_HEIGHT - BOTTOM_MARGIN - @pdf.GetY
                if height > space_left
                  @pdf.AddPage('L')
                  @render_new_header = true
                end

                @pdf.RDMwriteFormattedCell(@table_width, ROW_HEIGHT, '', '', description, entity.try(:attachments), 1)
              end

              render_custom_column(entity, attributes, level)
            end
            render_group_sum(attributes)
          end
        end
      end

      def render_custom_column(entity, attributes, level)

      end

      def prepare_pdf
        @pdf.SetTitle(title_and_name)
        @pdf.alias_nb_pages
        @pdf.footer_date = format_date(Date.today)
        @pdf.set_auto_page_break(false)
        @pdf.add_page("L")

        get_col_width
      end

      def get_col_width
        unless @query.inline_columns.empty?
          @col_width   = calc_col_width
          @table_width = @col_width.reduce(:+)
        end

        # use full width if the description is displayed
        if @table_width > 0 && @query.has_column?(:description)
          @col_width   = @col_width.map { |w| w * (PAGE_WIDTH - RIGHT_MARGIN - LEFT_MARGIN) / @table_width }
          @table_width = @col_width.reduce(:+)
        end
      end

      def calc_col_width
        set_style_header
        col_padding    = @pdf.get_string_width('OO')
        col_width_min  = @columns.map { |v| @pdf.get_string_width(v.caption) + col_padding }
        col_width_max  = Array.new(col_width_min)
        col_width_avg  = Array.new(col_width_min)
        word_width_max = @columns.map { |c|
          n = 10
          c.caption.split.each { |w|
            x = @pdf.get_string_width(w) + col_padding
            n = x if n < x
          }
          n
        }

        set_style_normal
        col_padding = @pdf.get_string_width('OO')
        k           = 1
        @entities.each do |group, attributes|
          if @query.open_category?(group)
            easy_query_entity_list(attributes[:entities]) do |entity, level|
              k      += 1
              values = row_values(entity, level)
              values.each_with_index { |v, i|
                n                = @pdf.get_string_width(v) + col_padding
                col_width_max[i] = n if col_width_max[i] < n
                col_width_min[i] = n if col_width_min[i] > n
                col_width_avg[i] += n
                v.split.each do |w|
                  x                 = @pdf.get_string_width(w) + col_padding
                  word_width_max[i] = x if word_width_max[i] < x
                end
              }
            end
          end
        end

        col_width_avg.map! { |x| x / k }

        # calculate columns width
        ratio     = @table_width / col_width_avg.inject(0, :+)
        col_width = col_width_avg.map { |w| w * ratio }

        # correct max word width if too many columns
        ratio = @table_width / word_width_max.inject(0, :+)
        word_width_max.map! { |v| v * ratio } if ratio < 1

        # correct and lock width of some columns
        done    = 1
        col_fix = []
        col_width.each_with_index do |w, i|
          if w > col_width_max[i]
            col_width[i] = col_width_max[i]
            col_fix[i]   = 1
            done         = 0
          elsif w < word_width_max[i]
            col_width[i] = word_width_max[i]
            col_fix[i]   = 1
            done         = 0
          else
            col_fix[i] = 0
          end
        end

        # iterate while need to correct and lock coluns width
        while done == 0
          # calculate free & locked columns width
          done           = 1
          fix_col_width  = 0
          free_col_width = 0
          col_width.each_with_index do |w, i|
            if col_fix[i] == 1
              fix_col_width += w
            else
              free_col_width += w
            end
          end

          # calculate column normalizing ratio
          if free_col_width == 0
            ratio = @table_width / col_width.inject(0, :+)
          else
            ratio = (@table_width - fix_col_width) / free_col_width
          end

          # correct columns width
          col_width.each_with_index do |w, i|
            if col_fix[i] == 0
              col_width[i] = w * ratio

              # check if column width less then max word width
              if col_width[i] < word_width_max[i]
                col_width[i] = word_width_max[i]
                col_fix[i]   = 1
                done         = 0
              elsif col_width[i] > col_width_max[i]
                col_width[i] = col_width_max[i]
                col_fix[i]   = 1
                done         = 0
              end
            end
          end
        end

        col_width
      end

      def make_title
        render_logo
        set_style_title
        @pdf.RDMCell(190, 10, title_and_name)
        @pdf.Ln
      end

      def render_header
        # header style
        set_style_header

        base_x = @pdf.GetX
        base_y = @pdf.GetY

        max_height = get_max_height(@columns, true)

        # background to all rows
        @pdf.Rect(base_x, base_y, @table_width, max_height, 'FD');
        @pdf.SetXY(base_x, base_y);

        render_row(@columns, true)
        render_borders(base_x, base_y, max_height)

        # new line
        @pdf.SetY(base_y + max_height)

        # rows
        set_style_normal
      end

      # Render it off-page to find the max height used
      def get_max_height(values, head = false)
        # base_y = @pdf.GetY
        # base_x = @pdf.GetX
        # @pdf.SetY(2 * PAGE_HEIGHT)
        # max_height = render_row(values, head)
        # @pdf.SetXY(base_x, base_y)
        # max_height

        max_height = ROW_HEIGHT
        values.each_with_index do |value, index|
          if head
            height = @pdf.get_string_height(@col_width[index], value.caption.to_s)
          else
            height = @pdf.get_string_height(@col_width[index], value)
          end
          max_height = height if height > max_height
        end
        max_height
      end

      def row_values(entity, level)
        values = []
        @columns.each do |column|
          value = format_value_for_export(entity, column, nil, @options)
          # level can be nil
          if [:name, :subject].include?(column.name)
            value = ("  " * level.to_i) + value
          end

          values << value
        end
        values
      end

      def render_group(group, attributes)
        value = format_value_for_export(@query.entity, @query.group_by_column, attributes[:name])
        value << " (#{easy_query_group_by_title_tags(@query, attributes[:count], attributes[:percent], attributes[:sums], { :plain => true })})" unless @options[:hide_sums_in_group_by]

        set_style_group
        @pdf.Bookmark(value, 0, -1)
        @pdf.RDMCell(@col_width.sum, ROW_HEIGHT * 2, value, 1, 1, 'L')
        set_style_normal
      end

      def render_row(values, head = false)
        base_y     = @pdf.GetY
        max_height = ROW_HEIGHT

        values.each_with_index do |column, i|
          col_x = @pdf.GetX
          if head
            @pdf.RDMMultiCell(@col_width[i], ROW_HEIGHT, column.caption.to_s, 'T', 'L', 1)
          elsif !@options[:no_html]
            @pdf.MultiCell(@col_width[i], ROW_HEIGHT, column, 'T', 'L', 1, 1, '', '', true, 0, true)
          else
            @pdf.RDMMultiCell(@col_width[i], ROW_HEIGHT, column, 'T', 'L', 1)
          end
          max_height = (@pdf.GetY - base_y) if (@pdf.GetY - base_y) > max_height
          @pdf.SetXY(col_x + @col_width[i], base_y)
        end

        max_height
      end

      def render_borders(top_x, top_y, height)
        col_x   = top_x
        lower_y = top_y + height

        @pdf.Line(col_x, top_y, col_x, lower_y) # id right border
        @col_width.each do |width|
          col_x += width
          @pdf.Line(col_x, top_y, col_x, lower_y) # columns right border
        end
        @pdf.Line(top_x, top_y, top_x, lower_y) # left border
        @pdf.Line(top_x, lower_y, col_x, lower_y) # bottom border
      end

      def render_group_sum(attributes)
        return unless @query.grouped?
        return unless sumable?

        set_style_sum
        @columns.each do |column|
          if column.sumable? && column.sumable_bottom?
            value = format_value_for_export(@query.entity, column, attributes[:sums][:bottom][column])
            @pdf.RDMCell(@col_width[@columns.index(column)], ROW_HEIGHT, value, 1, 0, 'L', 1)
          else
            @pdf.RDMCell(@col_width[@columns.index(column)], ROW_HEIGHT, '', 1, 0, 'L', 1)
          end
        end
        @pdf.Ln
        set_style_normal
      end

      def render_final_sum
        return unless sumable?

        set_style_final_sum
        @columns.each do |column|
          if column.sumable_bottom?
            # value = format_value_for_export(@query.entity, column, @entities.values.inject(0){|mem,var| (var[:sums] && var[:sums][:bottom]) ? mem += (var[:sums][:bottom][column] || 0).to_f : nil; mem })
            value = format_value_for_export(@query.entity, column, @query.entity_sum(column))
            @pdf.RDMCell(@col_width[@columns.index(column)], ROW_HEIGHT * 1.5, value, 1, 0, 'L', 1)
          else
            @pdf.RDMCell(@col_width[@columns.index(column)], ROW_HEIGHT * 1.5, (column == @columns.first ? l(:label_total_total) : ''), 1, 0, 'L', 1)
          end
        end
        @pdf.Ln
      end

      def sumable?
        if @columns.detect { |i| i.sumable? }
          true
        else
          false
        end
      end

      # Title of pdf and title on the header
      def title_and_name
        get_export_filename("", @query, @options[:default_title]).gsub(/\.\Z/, '')
      end

      # Styles
      # -----------------------------------------

      def set_style_header
        @pdf.SetFontStyle('B', 8)

        if theme
          @pdf.SetTextColor(theme.header_font_color_r, theme.header_font_color_g, theme.header_font_color_b)
          @pdf.SetDrawColor(theme.header_font_color_r, theme.header_font_color_g, theme.header_font_color_b)
          @pdf.SetFillColor(theme.header_color_r, theme.header_color_g, theme.header_color_b)
        else
          @pdf.SetTextColor(255, 255, 255)
          @pdf.SetDrawColor(255)
          @pdf.SetFillColor(57, 171, 227)
        end
      end

      def set_style_normal
        @pdf.SetFontStyle('', 8)
        @pdf.SetLineWidth(0.05)
        @pdf.SetDrawColor(175)
        @pdf.SetTextColor(0, 0, 0)
        @pdf.SetFillColor(255, 255, 255)
      end

      def set_style_title
        @pdf.SetFontStyle('B', 15)
      end

      def set_style_group
        @pdf.SetFontStyle('B', 9)
      end

      def set_style_sum
        @pdf.SetFontStyle('B', 9)
      end

      def set_style_final_sum
        @pdf.SetFontStyle('B', 10)
        @pdf.SetFillColor(230, 230, 230)
      end

    end
  end
end

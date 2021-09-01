Rys::Patcher.add('EasyExtensions::Export::Pdf') do

  apply_if_plugins :easy_extensions

  instance_methods(feature: 'show_last_comments_on_issue') do

    def initialize(entities, query, options = {})
      if query.has_column?(:last_comments)
        @last_comments = true
        query.column_names.delete(:last_comments)
      end
      super(entities, query, options)
    end

    def render_custom_column(entity, attributes, level)
      if @last_comments && !entity.last_comments.blank?

        s = @options[:view_context].format_html_last_comments(format_last_comments(entity.last_comments)).to_str

        last_comments = if @options[:view_context] && !@options[:no_html]
                          @options[:view_context].textilizable(s).to_str
                        else
                          Loofah::Helpers.strip_tags(s)
                        end

        height = @pdf.get_string_height(@table_width, last_comments)

        space_left = self.class::PAGE_HEIGHT - self.class::BOTTOM_MARGIN - @pdf.GetY
        if height > space_left
          @pdf.AddPage('L')
          @render_new_header = true
        end

        if @options[:no_html]
          @pdf.RDMMultiCell(@table_width, self.class::ROW_HEIGHT, last_comments, 'TRBL', 'L', 1)
        else
          @pdf.MultiCell(@table_width, self.class::ROW_HEIGHT, last_comments, 'TRBL', 'L', 1, 1, '', '', true, 0, true)
        end
      end
    end

    #TODO formating for column inline other
    # def row_values(entity, level)
    #   values = super(entity, level)
    #   if @last_comments
    #     @last_comment_index = @columns.find_index { |c| c.name == :last_comments }
    #     values[@last_comment_index] = @options[:view_context].render_last_comments(format_last_comments(entity.last_comments)).to_str
    #   end
    #   values
    # end
    #
    # def render_row(values, head = false)
    #   base_y = @pdf.GetY
    #
    #   is_query_column = values.first.is_a?(EasyQueryColumn)
    #   max_height = is_query_column ? self.class::ROW_HEIGHT : get_max_height(values)
    #
    #   values.each_with_index do |column, i|
    #     col_x = @pdf.GetX
    #     if head
    #       @pdf.RDMMultiCell(@col_width[i], max_height, column.caption.to_s, 'T', 'L', 1)
    #     elsif !@options[:no_html]
    #       @pdf.MultiCell(@col_width[i], max_height, column, 'T', 'L', 1, 1, '', '', true, 0, true)
    #     else
    #       @pdf.RDMMultiCell(@col_width[i], max_height, column, 'T', 'L', 1)
    #     end
    #     max_height = (@pdf.GetY - base_y) if (@pdf.GetY - base_y) > max_height
    #     @pdf.SetXY(col_x + @col_width[i], base_y)
    #   end
    #
    #   max_height
    # end
    #
    # def calc_col_width
    #   set_style_header
    #   col_padding = @pdf.get_string_width('OO')
    #   col_width_min = @columns.map {|v| @pdf.get_string_width(v.caption) + col_padding}
    #   col_width_max = Array.new(col_width_min)
    #   col_width_avg = Array.new(col_width_min)
    #   word_width_max = @columns.map { |c|
    #     n = 10
    #     c.caption.split.each {|w|
    #       x = @pdf.get_string_width(w) + col_padding
    #       n = x if n < x
    #     }
    #     n
    #   }
    #
    #   set_style_normal
    #   col_padding = @pdf.get_string_width('OO')
    #   k = 1
    #   @entities.each do |group, attributes|
    #     if @query.open_category?(group)
    #       easy_query_entity_list(attributes[:entities]) do |entity, level|
    #         k += 1
    #
    #         values = row_values(entity, level)
    #         values.each_with_index {|v,i|
    #           n = @pdf.get_string_width(v) + col_padding
    #           col_width_max[i] = n if col_width_max[i] < n
    #           col_width_min[i] = n if col_width_min[i] > n
    #           col_width_avg[i] += n
    #           v.split("\n").each do |w|
    #             x = @pdf.get_string_width(w) + col_padding
    #             word_width_max[i] = x if word_width_max[i] < x
    #           end
    #         }
    #       end
    #     end
    #   end
    #
    #   col_width_avg.map! {|x| x / k}
    #
    #   # calculate columns width
    #   ratio = @table_width / col_width_avg.inject(0, :+)
    #   col_width = col_width_avg.map {|w| w * ratio}
    #
    #   # correct max word width if too many columns
    #   ratio = @table_width / word_width_max.inject(0, :+)
    #   word_width_max.map! {|v| v * ratio} if ratio < 1
    #
    #   # correct and lock width of some columns
    #   done = 1
    #   col_fix = []
    #   col_width.each_with_index do |w,i|
    #     if w > col_width_max[i]
    #       col_width[i] = col_width_max[i]
    #       col_fix[i] = 1
    #       done = 0
    #     elsif w < word_width_max[i]
    #       col_width[i] = word_width_max[i]
    #       col_fix[i] = 1
    #       done = 0
    #     else
    #       col_fix[i] = 0
    #     end
    #   end
    #
    #   # iterate while need to correct and lock coluns width
    #   while done == 0
    #     # calculate free & locked columns width
    #     done = 1
    #     fix_col_width = 0
    #     free_col_width = 0
    #     col_width.each_with_index do |w,i|
    #       if col_fix[i] == 1
    #         fix_col_width += w
    #       else
    #         free_col_width += w
    #       end
    #     end
    #
    #     # calculate column normalizing ratio
    #     if free_col_width == 0
    #       ratio = @table_width / col_width.inject(0, :+)
    #     else
    #       ratio = (@table_width - fix_col_width) / free_col_width
    #     end
    #
    #     # correct columns width
    #     col_width.each_with_index do |w,i|
    #       if col_fix[i] == 0
    #         col_width[i] = w * ratio
    #
    #         # check if column width less then max word width
    #         if col_width[i] < word_width_max[i]
    #           col_width[i] = word_width_max[i]
    #           col_fix[i] = 1
    #           done = 0
    #         elsif col_width[i] > col_width_max[i]
    #           col_width[i] = col_width_max[i]
    #           col_fix[i] = 1
    #           done = 0
    #         end
    #       end
    #     end
    #   end
    #
    #   col_width
    # end
    #
    #


  end

end

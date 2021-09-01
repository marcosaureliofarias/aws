module EasyExtensions
  module Export
    class Csv
      
      EXPORTABLE_OUTPUTS = %w(list report)
      attr_accessor :query, :options
      
      def initialize(query, view_context, options = {})
        @query    = query
        @options  = options
        @view_context = view_context
        @outputs = @query.outputs & EXPORTABLE_OUTPUTS # array ['list', 'report'..]
      end

      def output
        create
      end

      def h
        @view_context
      end

      private

      def create
        Redmine::Export::CSV.generate do |csv|
          @outputs.each_with_index do |output, i|
            export_output_class = "EasyExtensions::Export::#{output.titleize}CsvExport".safe_constantize
            if export_output_class.present?
              export_output_class.new(self, csv).create
              csv << [] if @outputs[i + 1].present?# add empty row
            end
          end
        end
      end
    end

    class OuputCsvExport
      delegate :query, :options, :h, to: :@exporter

      include EasyQueryHelper
      include EntityAttributeHelper
      include Redmine::I18n
      include CustomFieldsHelper
      include ApplicationHelper

      def initialize(query_exporter, csv)
        @csv = csv
        @exporter = query_exporter
      end

      def create
        render_headers
        render_records
      end

      def render_headers
      end

      def render_records
      end
    end

    class ListCsvExport < OuputCsvExport

      def entities
        return @entities unless @entities.nil?
        @entities = options[:entities] || query.prepare_export_result(options)
      end

      def columns
        return @columns unless @columns.nil?
        @columns = options[:columns] || query.columns
      end

      def render_headers
        @csv << columns.map { |c| c.caption.to_s }
      end

      def render_row(entity)
        columns.map { |column| format_value_for_export(entity, column) }
      end

      def render_records
        # old Export to csv
        if entities.is_a?(Array)
          entities.each do |entity|
            @csv << render_row(entity)
          end
          return
        end
        # new Export to csv
        entities.each do |_group, attributes|
          attributes[:entities].each do |entity|
            @csv << render_row(entity)
          end
        end
      end
    end

    class ReportCsvExport < OuputCsvExport
      attr_accessor :output
      
      def initialize(query_exporter, csv)
        super
        return self unless available_for?

        query_presenter = EasyExtensions::EasyQueryHelpers::EasyQueryPresenter.new(query, h)
        @output = EasyExtensions::EasyQueryOutputs::ReportOutput.new(query_presenter)
      end

      def create
        return unless output.present?
        output.render_callback do
          if render?
            render_headers
            render_records
          end
        end
      end

      def render_headers
        groups_count = output.report_values.keys.first.count
        sum_count = output.sum_column.count
        empty_sub_row = Array.new(groups_count - 1, nil)
        top_group_headings = []
        output.top_line.map do |column_heading|
          top_group_headings << output.format_group(groups_count-1, output.top_line_names[column_heading], output.top_line_entities[column_heading], true)
          top_group_headings += Array.new(sum_count - 1, nil)
        end
        @csv << empty_sub_row + top_group_headings + [l(:label_total)]
        if sum_count > 1
          top_sum_headings = []
          (output.top_line + [:any]).each do |column_heading|
            output.sum_column.each do |sum_col|
              top_sum_headings << (sum_col && sum_col.caption || l(:field_count))
            end
          end
          @csv << empty_sub_row + top_sum_headings
        end
      end

      def render_records
        last = nil
        bottom_total = output.bottom_total
        left_groups_count = output.left_report_group_by.count
        sum_column_count = output.sum_column.count

        output.groups.each do |group, top_groups|
          row_values = []
          right_total = output.sum_column.map { |sc| 0 }
          diff = 0;
          group.each_with_index do |val, i|
            column_group = output.column_group(top_groups.first, group)
            diff += 1 and next if last && val == last[i]
            last = nil
            if diff > 0
              row_values += Array.new(diff, nil)
              diff = 0
            end
            row_values << output.format_group(i, output.group_name(column_group)[i], output.group_entity(column_group), true)
          end
          top_groups = output.sort_top_line(top_groups)
          i = 0
          output.top_line.each do |column_heading|
            if i >= top_groups.length || top_groups[i] != column_heading
              row_values << '-'
              row_values += Array.new(sum_column_count - 1, nil)
            else
              (0...sum_column_count).step do |col_idx|
                col_group = output.column_group( column_heading, group )
                val = output.column_value( col_group, col_idx )
                output.fixed_value_column_indexes.include?(col_idx) ? right_total[col_idx] = val : right_total[col_idx] += val
                bottom_total[column_heading][col_idx] += val.nil? ? 0 : val
                row_values << output.format_value(val, col_group, col_idx, { no_html: true, for_export: true })
              end
              i += 1
            end
          end
          (0...sum_column_count).step do |col_idx|
            bottom_total[:total][col_idx] += right_total[col_idx]
            row_values << output.format_value(right_total[col_idx], output.column_group(:any, group), col_idx, { no_html: true, for_export: true } )
          end
          @csv << row_values
        end
        row_values = []
        bottom_total.each_with_index do |(key, value), idx|
          value.each_with_index do |val, i|
            row_values << (key == :label ? val : output.format_value(val, nil, i, { no_html: true, for_export: true }))
            row_values += Array.new(left_groups_count - 1, nil) if idx == 0
          end
        end
        @csv << row_values
      end

      def available_for?
        EasyExtensions::EasyQueryOutputs::ReportOutput.available_for?(query)
      end

      def render?
        query.grouped? && !(query.group_by_column.count < 2) && output.groups.any?
      end
    end
  end
end

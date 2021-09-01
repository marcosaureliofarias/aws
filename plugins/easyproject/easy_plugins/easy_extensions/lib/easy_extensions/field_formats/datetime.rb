module EasyExtensions
  module FieldFormats

    class Datetime < Redmine::FieldFormat::Unbounded
      add 'datetime'
      self.type_for_inline_edit = nil

      include EasyExtensions::EasyQueryExtensions::DateTime

      attr_writer :period

      def label
        :label_datetime_custom_field
      end

      def date?(_custom_field)
        true
      end

      def date_time?(_custom_field)
        true
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options = {})
        edit_tag(view, tag_id, tag_name, CustomFieldValue.new, options) +
            bulk_clear_tag(view, tag_id + '_date', tag_name, custom_field, value)
      end

      def get_value_from_params(value)
        datetime = EasyUtils::DateUtils.build_datetime_from_params(value)
        datetime.utc.to_s(:db) if datetime
      end

      def cast_single_value(custom_field, value, customized = nil)
        return if value.blank?
        datetime = begin
          ; DateTime.parse(value, :utc);
        rescue;
        end
        if datetime
          if User.current.time_zone
            datetime.in_time_zone(User.current.time_zone)
          else
            datetime.localtime
          end
        end
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        s                 = "<span class='datetime'>"
        selected_datetime = cast_single_value(nil, custom_value.value)
        s << view.text_field_tag(tag_name + '[date]', selected_datetime && selected_datetime.to_date, { :id => (tag_id + '_date'), :size => 10 }.merge(options))
        s << '<span class="flex-center">' + view.select_tag(tag_name + '[hour]', view.options_for_select(24.times.collect { |i| [i, i] }, :selected => selected_datetime && selected_datetime.hour), :id => (tag_id + '_hour'), :class => 'datetime-custom-field-tag-hour inline')
        s << l(:label_datetime_custom_field_tag_hour) + '</span>'
        s << '<span class="flex-center">' + view.select_tag(tag_name + '[minute]', view.options_for_select([['00', '00'], ['15', '15'], ['30', '30'], ['45', '45']], :selected => selected_datetime && selected_datetime.min.to_s), :id => (tag_id + '_minute'), :class => 'datetime-custom-field-tag-minute inline')
        s << l(:label_datetime_custom_field_tag_minute) + '</span>'
        s << view.calendar_for((tag_id + '_date'))
        s << '</span>'
        s.html_safe
      end

      def query_filter_options(custom_field, query)
        { :type => :date_period }
      end

      def custom_value_before_save(custom_value)
        v                  = custom_value.value
        v                  = v.utc.to_s(:db) if v.is_a?(Time) && !v.utc?
        custom_value.value = v
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        format_time(cast_single_value(custom_field, value), true)
      rescue;
        value
      end

      def order_statement(custom_field)
        statement = timestamp_cast(super)
        if @period
          statement = date_condition(statement, @period)
        end
        Arel.sql(custom_field.class.send(:sanitize_sql_array, statement))
      end

      def group_statement(custom_field)
        order_statement(custom_field)
      end
    end

  end
end

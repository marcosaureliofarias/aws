module EasyExtensions
  module FieldFormats
    class ValueTree < Redmine::FieldFormat::List
      add 'value_tree'
      self.multiple_supported   = false
      self.searchable_supported = true
      self.type_for_inline_edit = 'valuetree'
      self.form_partial         = 'custom_fields/formats/value_tree'

      SEPARATOR_MARK = '>'

      VALUE_STRUCT   = Struct.new(:level, :value)
      COUNTER_STRUCT = Struct.new(:i)

      def possible_values_for_edit_page(custom_field)
        values = custom_field.possible_values
        make_simple_tree!(values)
        values
      end

      # Format: [[value, id]]
      def possible_values_for_report(custom_field)
        values = custom_field.possible_values.dup
        make_simple_tree!(values)
        values.zip(custom_field.possible_values)
      end

      def possible_custom_value_options(custom_value)
        options = possible_values_options(custom_value.custom_field)
        missing = [custom_value.value].flatten.reject(&:blank?) - options
        if missing.any?
          options += missing
        end
        options
      end

      def possible_values_options(custom_field, object = nil)
        custom_field.possible_values
      end

      def validate_custom_field(custom_field)
        values = custom_field.possible_values.dup

        errors = []
        errors << [:possible_values, :blank] if values.blank?
        errors << [:possible_values, :invalid] unless values.is_a?(Array)

        if errors.empty?
          # Add level
          map_to_value_struct!(values)

          # First line must have level 0
          if values.first && values.first.level != 0
            errors << [:possible_values, :invalid]
          else
            # Current level must be compared with the previus:
            # - the same
            # - higher by one
            # - smaller
            prev_level = 0
            values.each do |value|
              if value.level > (prev_level + 1)
                errors << [:possible_values, :invalid]
                break
              end

              prev_level = value.level
            end
          end
        end

        errors
      end

      def validate_custom_value(custom_value)
        values         = Array.wrap(custom_value.value).reject { |value| value.to_s == '' }
        invalid_values = values - Array.wrap(custom_value.value_was) - custom_value.custom_field.possible_values
        if invalid_values.any?
          [::I18n.t('activerecord.errors.messages.inclusion')]
        else
          []
        end
      end

      def group_statement(custom_field)
        order_statement(custom_field)
      end

      # Renders the edit tag as a select tag
      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        values = custom_value.custom_field.possible_values

        # Make tree
        make_tree_for_select!(values)

        # Create options
        blank_option = ''.html_safe
        if custom_value.custom_field.is_required?
          unless custom_value.custom_field.default_value.present?
            blank_option = view.content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '')
          end
        else
          blank_option = view.content_tag('option', '&nbsp;'.html_safe, :value => '')
        end
        options_tags = blank_option
        options_tags += view.options_for_select(values, custom_value.value)

        # Select by options
        view.select_tag(tag_name, options_tags, options.merge(id: tag_id))
      end

      def formatted_custom_value(view, custom_value, html = false)
        value = custom_value.value

        return if value.nil?

        html ? make_html_tree!(value.split(SEPARATOR_MARK)).html_safe : value
      end

      def source_values_for_inline_edit(custom_field_value)
        # There must be a `.dup` because of query grouping
        values = possible_values_options(custom_field_value.custom_field).dup
        make_tree_for_select!(values)

        values.map! do |value|
          { text: value[0], value: value[1] }
        end

        values
      end

      def before_custom_field_save(custom_field)
        super
        values = custom_field.possible_values

        # Add level
        map_to_value_struct!(values)

        # Format values based on level
        format_values!(values, COUNTER_STRUCT.new(0), '')

        # Save only values
        values.map!(&:value)
        custom_field.possible_values = values
      end

      private

      def map_to_value_struct!(values)
        # Add level to values
        values.map! do |value|
          value = value.match(/([#{SEPARATOR_MARK}]*)[\ ]*(.+)/)
          if value
            VALUE_STRUCT.new(value[1].size, value[2])
          else
            nil
          end
        end

        # Invalid values are nil
        values.compact!
      end

      def format_values!(values, counter, parent)
        loop {
          current_value = values[counter.i]
          next_value    = values[counter.i + 1]

          # If last value level > 0
          return if current_value.nil?

          current_value.value = "#{parent}#{" #{SEPARATOR_MARK} " unless current_value.level.zero?}#{current_value.value}"
          counter.i           += 1

          # There are no more values
          return if next_value.nil?

          if current_value.level == next_value.level
            # same level
            # continue
          elsif current_value.level > next_value.level
            # next is higher
            return
          elsif current_value.level < next_value.level
            # next is lower
            format_values!(values, counter, current_value.value)

            # format_values returned to different level
            #
            # can happen if
            #
            # Value 1
            # > Value 1.1
            # >> Value 1.1.1
            # >>> Value 1.1.1.1
            # Value 2
            new_current_value = values[counter.i]
            if new_current_value.nil? || current_value.level != new_current_value.level
              return
            end
          end
        }
      end

      def make_tree_for_select!(values)
        values.map! do |value|
          split = value.split(SEPARATOR_MARK)

          name  = split.pop
          level = split.size

          prefix = (level > 0 ? '|&nbsp;&nbsp;' * level + '&#8627; ' : '')
          prefix = prefix.slice(1, prefix.size) if prefix.size > 0

          [(prefix + name).html_safe, value]
        end
      end

      def make_html_tree!(values)
        value = values.shift

        result = "<ul class='cf-value-tree'><li>#{value}"
        if values.any?
          result << make_html_tree!(values)
        end
        result << "</li></ul>"
        result
      end

      def make_simple_tree!(values)
        values.map! do |value|
          split = value.split(SEPARATOR_MARK)

          name  = split.pop
          level = split.size

          "#{SEPARATOR_MARK * level}#{name}"
        end
      end

    end
  end
end

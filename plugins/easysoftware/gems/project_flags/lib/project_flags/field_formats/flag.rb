module ProjectFlags
  module FieldFormats

    class Flag < Redmine::FieldFormat::List
      add 'flag'

      self.form_partial = nil

      self.type_for_inline_edit = 'flag'

      def label
        :label_flag
      end

      def possible_values_options(_custom_field, _object=nil)
        %w[red yellow green]
      end

      def formatted_value(view, custom_field, value, customized=nil, html=false)
        if html
          if custom_field.multiple? && value.is_a?(Array)
            value.map { |v| flag_tag(v, view) }.join.html_safe
          else
            flag_tag(value, view)
          end
        else
          if custom_field.multiple? && value.is_a?(Array)
            value.join(', ')
          else
            value.to_s
          end
        end
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options={})
        opts = []
        unless custom_value.custom_field.multiple? || custom_value.custom_field.is_required?
          opts << ["(#{l(:label_none)})", '']
        end
        opts.concat possible_custom_value_options(custom_value)
        s = ''.html_safe
        tag_method = custom_value.custom_field.multiple? ? :check_box_tag : :radio_button_tag
        opts.each do |label, value|
          value ||= label
          checked = (custom_value.value.is_a?(Array) && custom_value.value.include?(value)) || custom_value.value.to_s == value
          tag = view.send(tag_method, tag_name, value, checked, id: nil)
          if value.present?
            s << view.content_tag('label', tag + view.content_tag(:i, nil, class: "icon icon-project-flag icon-project-flag-#{value}"))
          else
            s << view.content_tag('label', tag + ' ' + label)
          end
        end
        if custom_value.custom_field.multiple?
          s << view.hidden_field_tag(tag_name, '', id: nil)
        end
        css = "#{options[:class]} check_box_group"
        view.content_tag('span', s, options.merge(class: css))
      end

      def group_statement(custom_field)
        order_statement(custom_field)
      end

      private

      def flag_tag(value, view_context)
        view_context.content_tag(:i, nil, class: "icon icon-project-flag icon-project-flag-#{value}")
      end

    end

  end
end
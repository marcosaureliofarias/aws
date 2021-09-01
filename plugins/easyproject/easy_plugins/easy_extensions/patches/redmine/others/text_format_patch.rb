module EasyPatch
  module TextFormatPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        self.type_for_inline_edit = 'textarea'

        def group_statement(custom_field)
          Arel.sql "COALESCE(#{join_alias custom_field}.value, '')"
        end

        def edit_tag(view, tag_id, tag_name, custom_value, options = {})
          result = ::ActiveSupport::SafeBuffer.new
          result << view.text_area_tag(tag_name, custom_value.value, options.merge(id: tag_id, rows: 3, class: 'wiki-edit'))
          result << view.wikitoolbar_for(tag_id) if custom_value.custom_field.text_formatting == 'full'
          result
        end

        def formatted_with_inline_edit(view, custom_field_value, formatted_value, options = {})
          if custom_field_value.custom_field.text_formatting == 'full'
            result    = ::ActiveSupport::SafeBuffer.new
            enabled   = custom_field_value.customized && custom_field_value.custom_field
            editable = custom_field_value.inline_editable?
            css_klass = ''
            if editable
              css_klass << 'editable'
              css_klass << ' editable-empty' if formatted_value.blank?
            end

            result << view.content_tag(:span, (formatted_value.blank? && enabled) ? '-' : formatted_value,
                                       class: css_klass, data: {
                    tag_id: view.custom_field_tag_id('longtext', custom_field_value.custom_field),
                }.merge!(options[:data] || {}))

            return result unless enabled && editable

            edit_click_js = %Q(
              event.stopPropagation();
              var btn = $(this);
              btn.siblings('.editable').addClass('edited');
              btn.siblings('.editable').removeClass('editable-empty');
              var url = btn.closest('.multieditable-container').data().url;
              $.get('#{view.custom_fields_edit_long_text_path(:id => custom_field_value.custom_field, :customized_id => custom_field_value.customized.id, :customized_class => custom_field_value.customized.class, :format => 'js')}', {'url': url})
            )
            result << view.content_tag(:span, '', :class => 'icon-edit', :title => l(:title_inline_editable), :style => 'position: inherit', :onclick => edit_click_js)
            return result
          else
            super
          end
        end

      end
    end

    module InstanceMethods

    end

  end
end

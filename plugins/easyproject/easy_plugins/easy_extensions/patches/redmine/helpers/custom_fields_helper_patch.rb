module EasyPatch
  module CustomFieldsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :custom_field_label_tag, :easy_extensions
        alias_method_chain :custom_field_name_tag, :easy_extensions
        alias_method_chain :custom_field_tag_with_label, :easy_extensions
        alias_method_chain :custom_field_tag, :easy_extensions
        alias_method_chain :custom_field_tag_for_bulk_edit, :easy_extensions
        alias_method_chain :custom_field_tag_id, :easy_extensions
        alias_method_chain :custom_field_type_options, :easy_extensions
        alias_method_chain :render_api_custom_values, :easy_extensions
        alias_method_chain :show_value, :easy_extensions
        alias_method_chain :custom_field_formats_for_select, :easy_extensions
        alias_method_chain :edit_tag_style_tag, :easy_extensions

        def easy_lookup_entity_custom_fields_options(type)
          CustomField.where(
              :type         => "#{type}CustomField",
              :field_format => available_easy_lookup_entity_custom_field_formats
          ).order("#{CustomField.table_name}.name ASC").select(:name, :id).map { |cf| [cf.name, cf.id] }
        end

        def available_easy_lookup_entity_custom_field_formats
          [
              'amount', 'autoincrement', 'bool', 'date', 'datetime', 'float', 'int', 'string', 'text',
              'country_select', 'easy_percent', 'easy_rating', 'email', 'link', 'list',
              'easy_google_map_address', 'value_tree'
          ]
        end

        # CUSTOM FIELD TAGS
        #
        # => "custom field type"_field_tag(custom_field, custom_value, field_name, field_id, options = {})

        def render_api_custom_value_easy_lookup(entity, api)
          format = params[:format] || request.format.symbol

          if format.to_s == 'json'
            # original api.id entity.id
            # cannot use api.id, because it rewrites custom field id in json api
            # cannot add key, because value is serialized to array
            # key named value is used on every custom field instead of lookup
            # breaking change for XML data api
            api.value entity.id
          else
            api.id entity.id
          end

          api.name entity.to_s
          # default_url_options are necessary for calls in easy_jobs
          api.url url_to_entity(entity, Mailer.default_url_options.merge(format: format, only_path: false))
        end

        def unsupported_field_formats
          [EasyExtensions::FieldFormats::EasyRating.instance.name]
        end

        def render_show_entity_custom_fields(entity, grouped_custom_field_values, layout = :two_columns, options = {})
          render_method = "render_show_entity_custom_fields_#{layout}"
          tabs          = []
          html          = ''
          grouped_custom_field_values.each do |group, custom_field_values|
            next if group.nil?
            tab         = {}
            tab[:label] = group.name
            tab[:name]  = group.id
            if respond_to?(render_method)
              tab[:inline] = content_tag(:div,
                                         send(render_method, entity, custom_field_values, options).html_safe,
                                         class: "#{entity.class.name.underscore.dasherize}-custom-filed-values #{layout}"
              )
            else
              tab[:inline] = l(:notice_render_show_cf_values_mehod_not_found)
            end
            tab[:css_classes] = 'custom-fields'
            tabs << tab
          end
          if respond_to?(render_method)
            html.concat(content_tag(:div,
                                    send(render_method, entity, grouped_custom_field_values[nil], options).html_safe,
                                    class: "#{entity.class.name.underscore.dasherize}-custom-filed-values #{layout}"
                        )) if grouped_custom_field_values[nil]
            html.concat(render_tabs(tabs, tabs.first[:name], render_type: 'inline', static_url: true)) if tabs.any?
          else
            html = l(:notice_render_show_cf_values_mehod_not_found)
          end
          html.html_safe
        end

        def content_tag_for_entity_custom_field_value(entity, value, _options = {})
          return content_tag(:div,
                             "#{content_tag(:span, h(value.custom_field.translated_name) + ':')} #{show_value(value)}".html_safe,
                             class: "view-#{entity.class.name.underscore.dasherize}-custom-field splitcontent"
          )
        end

        def render_show_entity_custom_fields_one_column(entity, custom_field_values, _options = {})
          cfs = ''
          custom_field_values.each do |value|
            cfs << content_tag_for_entity_custom_field_value(entity, value)
          end

          cfs.html_safe
        end

        def render_show_entity_custom_fields_one_column_table(_entity, custom_field_values, options = {})
          cfs = issue_fields_rows do |rows|
            custom_field_values.each do |value|
              rows.left(
                  h(value.custom_field.translated_name),
                  show_value(value, true, options),
                  label_options: {
                      title: value.custom_field.description.presence,
                      class: 'field-description'
                  }
              )
            end
          end
          content_tag(:div, cfs.html_safe, class: 'attributes')
        end

        def render_show_entity_custom_fields_two_columns(_entity, custom_field_values, options = {})
          cfs = issue_fields_rows do |rows|
            custom_field_values.each_with_index do |value, i|
              #item = content_tag_for_entity_custom_field_value(value)
              if i.even?
                rows.left(
                    h(value.custom_field.translated_name),
                    show_value(value, true, options),
                    label_options: {
                        title: value.custom_field.description.presence,
                        class: 'field-description'
                    }
                )
              else
                rows.right(
                    h(value.custom_field.translated_name),
                    show_value(value, true, options),
                    label_options: {
                        title: value.custom_field.description.presence,
                        class: 'field-description'
                    }
                )
              end
            end
          end

          content_tag(:div, cfs.html_safe, class: 'attributes')
        end
      end
    end

    module InstanceMethods

      def custom_field_tag_with_label_with_easy_extensions(name, custom_value, label_tag_options = {}, custom_field_tag_options = {})
        custom_field_label_tag(name, custom_value, label_tag_options) + conditional_content_tag(custom_field_tag_options[:append], :span, :class => 'input-append') do
          append = custom_field_tag_options.delete(:append)
          if append
            custom_field_tag(name, custom_value, custom_field_tag_options) + append
          else
            custom_field_tag(name, custom_value, custom_field_tag_options)
          end
        end
      end

      # Return custom field html tag corresponding to its format
      def custom_field_tag_with_easy_extensions(prefix, custom_value, options = {})
        custom_field = custom_value.custom_field
        uniq_id      = options.delete(:uniq_id)
        field_name   = custom_field_tag_name(prefix, custom_field)
        field_id     = "#{custom_field_tag_id(prefix, custom_field)}_#{uniq_id}"

        if !custom_field.internal_name.blank? &&
            (format_field_value_method = "#{custom_field.internal_name.underscore}_custom_field_tag".to_sym) && respond_to?(format_field_value_method)
          send(format_field_value_method, custom_field, custom_value, field_name, field_id, options)
        else
          custom_value.custom_field.format.edit_tag self,
                                                    "#{custom_field_tag_id(prefix, custom_value.custom_field)}_#{uniq_id}",
                                                    custom_field_tag_name(prefix, custom_value.custom_field),
                                                    custom_value, options.reverse_merge({
                                                                                            class: "#{custom_value.custom_field.field_format}_cf",
                                                                                            data:  { internal_name: custom_value.custom_field.internal_name }
                                                                                        })
        end
      end

      def custom_field_tag_id_with_easy_extensions(prefix, custom_field)
        "#{convert_form_name_to_id(prefix.to_s)}_custom_field_values_#{custom_field.id}"
      end

      # Returns the custom field tag for when bulk editing objects
      def custom_field_tag_for_bulk_edit_with_easy_extensions(prefix, custom_field, objects = nil, value = '', options = {})
        custom_field.format.bulk_edit_tag self,
                                          custom_field_tag_id(prefix, custom_field),
                                          custom_field_tag_name(prefix, custom_field),
                                          custom_field,
                                          objects,
                                          value,
                                          options.merge({ :class => "#{custom_field.field_format}_cf" })
      end

      def show_value_with_easy_extensions(custom_value, html = true, options = {})
        return ''.html_safe unless custom_value

        formatted = if !custom_value.custom_field.internal_name.blank? &&
            (format_field_value_method = "format_custom_field_#{custom_value.custom_field.internal_name.underscore}_value".to_sym) &&
            respond_to?(format_field_value_method)
                      send(format_field_value_method, custom_value, { :no_html => !html }.merge(options)) || ''
                    else
                      show_value_without_easy_extensions(custom_value, html) || ''
                    end

        if options[:inline_editable] && html && custom_value.inline_editable?
          custom_value.custom_field.format.formatted_with_inline_edit(
              self, custom_value, formatted, options
          )
        else
          formatted
        end
      end

      def custom_field_name_tag_with_easy_extensions(custom_field)
        title = custom_field.description.presence
        css   = title ? 'field-description' : nil
        content_tag(:span, custom_field.translated_name, :title => title, :class => css)
      end

      def custom_field_label_tag_with_easy_extensions(name, custom_field_value, options = {})
        if custom_field_value.custom_field.field_format != 'easy_rating' ||
            !custom_field_value.customized.custom_value_for(custom_field_value.custom_field).user_already_rated? ||
            !custom_field_value.value.blank?

          required = options[:required] || custom_field_value.custom_field.is_required?

          # Workflow
          if !required && custom_field_value.customized.is_a?(Issue)
            required = custom_field_value.customized.required_attribute?(custom_field_value.custom_field.id)
          end

          additional_classes = ["#{custom_field_value.custom_field.field_format}_cf"]
          additional_classes << 'required' if required

          content = custom_field_name_tag(custom_field_value.custom_field)

          content_tag(:label, (content +
              (required ? ' <span class="required">*</span>'.html_safe : '')),
                      { :for => "#{convert_form_name_to_id(name.to_s)}_custom_field_values_#{custom_field_value.custom_field.id}_#{options.delete(:uniq_id)}", :class => additional_classes.join(' ').presence }.merge(options))
        else
          ''.html_safe
        end
      end

      def render_api_custom_values_with_easy_extensions(custom_values, api)
        api.array :custom_fields do
          custom_values.each do |custom_value|
            attrs                    = { :id => custom_value.custom_field_id, :name => custom_value.custom_field.translated_name, :internal_name => custom_value.custom_field.internal_name }
            attrs[:multiple]         = true if custom_value.custom_field.multiple?
            attrs[:easy_external_id] = custom_value.custom_field.easy_external_id unless custom_value.custom_field.easy_external_id.blank?
            attrs[:field_format]     = custom_value.custom_field.field_format
            api.custom_field attrs do
              if custom_value.custom_field.field_format == 'easy_lookup'
                if custom_value.cast_value.is_a?(Array)
                  api.array :value do
                    custom_value.cast_value.each do |value|
                      render_api_custom_value_easy_lookup(value, api)
                    end
                  end
                else
                  render_api_custom_value_easy_lookup(custom_value.cast_value, api) unless custom_value.cast_value.blank?
                end
              elsif custom_value.value.is_a?(Array)
                api.array :value do
                  custom_value.value.each do |value|
                    api.value(value) unless value.blank?
                  end
                end
              else
                api.value(custom_value.value)
              end
              if custom_value.custom_field.field_format == "datetime"
                api.local_datetime custom_value.custom_field.format.cast_single_value custom_value.custom_field, custom_value.value
              end
            end
          end
        end unless custom_values.empty?
      end

      def custom_field_type_options_with_easy_extensions
        custom_field_type_options_without_easy_extensions.sort_by { |a, b| a }
      end

      def custom_field_formats_for_select_with_easy_extensions(custom_field)
        Redmine::FieldFormat.as_select(custom_field.class.customized_class.name).reject { |_, name| unsupported_field_formats.include?(name) }
      end

      def edit_tag_style_tag_with_easy_extensions(form, options = {})
        select_options = [[l(:label_drop_down_list), ''], [l(:label_checkboxes), 'check_box']]
        if options[:include_radio]
          select_options << [l(:label_radio_buttons), 'radio']
        end
        if options[:type] == 'list'
          select_options << [l(:label_autocomplete), 'autocomplete', :disabled => !options[:multiple]]
        end
        form.select :edit_tag_style, select_options, :label => :label_display
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'CustomFieldsHelper', 'EasyPatch::CustomFieldsHelperPatch'

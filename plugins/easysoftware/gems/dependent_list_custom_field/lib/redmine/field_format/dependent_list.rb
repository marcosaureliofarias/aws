module Redmine
  module FieldFormat
    class DependentList < Redmine::FieldFormat::List
      include ActionView::Helpers::JavaScriptHelper

      add 'dependent_list'
      self.multiple_supported = false
      self.searchable_supported = true
      self.type_for_inline_edit = 'dependentlist'
      self.form_partial = 'custom_fields/formats/dependent_list'

      def select_edit_tag(view, tag_id, tag_name, custom_value, options = {})
        unless Rys::Feature.active?('dependent_list_custom_field')
          s = super(view, tag_id, tag_name, custom_value, options)
          return s
        end
        blank_option = ''.html_safe
        cf = custom_value.custom_field
        unless cf.multiple?
          if cf.is_required?
            unless cf.default_value.present?
              blank_option = view.content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", value: '')
            end
          else
            blank_option = view.content_tag('option', '&nbsp;'.html_safe, value: '')
          end
        end
        options_tags = blank_option
        options.merge!(id: tag_id, multiple: cf.multiple?, 'data-dependency' => "#{cf.type.underscore}_#{cf.id}_list")
        s = view.select_tag(tag_name, options_tags, options)
        if cf.multiple?
          s << view.hidden_field_tag(tag_name, '')
        end

        dependency_settings = cf.dependency_settings
        return s if dependency_settings.blank?

        parent_cf = cf.dependent_parent_cf
        return s if parent_cf.nil?
        parent_cf_data_dependency = "#{parent_cf.type.underscore}_#{parent_cf.id}_list"
        parent_cf_values = parent_cf.possible_values

        values = cf.possible_values
        script = 'window.dependentCfMatrix = window.dependentCfMatrix || {};'
        script << "window.dependentCfMatrix['#{cf.id}'] = new Array();"
        dependency_settings.each do |key, value|
          value.select {|k, v| v == '1' }.keys.each do |v|
            script << "window.dependentCfMatrix['#{cf.id}'].push(new Array('#{j(parent_cf_values[key.to_i])}','#{j(values[v.to_i])}'));"
          end
        end
        script << %Q{
          EASY.schedule.late(() => {
            new EASY.customFields.DependentCustomFieldList('#{cf.id}', '#{tag_id}', '#{j(custom_value.value)}', '#{parent_cf_data_dependency}');
          });}
        s << view.javascript_tag(script)
        s
      end

      def validate_custom_field(custom_field)
        errors = []
        errors << [:possible_values, :blank] if custom_field.possible_values.blank?
        errors << [:possible_values, :invalid] unless custom_field.possible_values.is_a? Array
        errors
      end

      def validate_custom_value(custom_value)
        values = Array.wrap(custom_value.value).reject {|value| value.to_s == ''}
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

      def possible_values_options(custom_field, project = nil)
        custom_field.possible_values
      end

      def source_values_for_inline_edit(custom_field_value)
        customized = custom_field_value.customized
        Rails.application.routes.url_helpers.easy_autocomplete_path(
            'dependent_list_possible_values',
            customized_id: customized.id,
            customized_type: customized.class.name,
            custom_field_id: custom_field_value.custom_field.id
        )
      end
    end
  end
end

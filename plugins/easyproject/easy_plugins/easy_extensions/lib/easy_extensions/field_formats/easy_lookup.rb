module EasyExtensions
  module FieldFormats

    class EasyLookup < Redmine::FieldFormat::RecordList
      add 'easy_lookup'

      self.multiple_supported     = true
      self.form_partial           = 'custom_fields/formats/easy_lookup'
      self.customized_class_names = nil
      self.type_for_inline_edit   = nil

      def self.entity_to_lookup_values(entity, options = {})
        entities               = Array(entity)
        lookup_values          = {}
        options[:id]           ||= :id
        options[:display_name] ||= :to_s

        entities.each do |e|
          if options[:id].is_a?(Symbol)
            id = e.send(options[:id])
          elsif options[:id].is_a?(Proc)
            id = options[:id].call(e)
          end
          if options[:display_name].is_a?(Symbol)
            display_name = e.send(options[:display_name])
          elsif options[:display_name].is_a?(Proc)
            display_name = options[:display_name].call(e)
          end

          lookup_values[id] = display_name.to_str if id && display_name
        end

        lookup_values
      end

      def self.entity_ids_to_lookup_values(entity_type, ids, options = {})
        return {} if ids.blank?
        begin
          entity_class = entity_type.constantize
        rescue
          return {}
        end
        entities = entity_class.where(:id => ids).to_a
        return {} if entities.blank?
        options[:display_name] ||= options[:attribute].to_s.sub('link_with_', '').to_sym if options[:attribute]
        entity_to_lookup_values(entities, options)
      end

      def label
        :label_easy_lookup
      end

      def get_value_from_params(value)
        if value == 'me'
          User.current.id
        else
          super
        end
      end

      def validate_custom_value(custom_value)
        values = Array.wrap(custom_value.value).reject { |value| value.to_s == '' }
        errors = values.map do |value|
          validate_single_value(custom_value.custom_field, value, custom_value.customized)
        end
        errors.flatten.uniq
      end

      def validate_custom_field(custom_field)
        settings = custom_field.settings
        errors   = []
        errors << [:settings, :blank] if settings['entity_attribute'].blank? || settings['entity_type'].blank?
        errors
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        options[:url] = options[:url] || {}
        values        = view.params.to_unsafe_hash.value_from_nested_key(tag_name)
        if values.blank?
          values = custom_value.value
        end

        values = [values] unless values.is_a?(Array)

        if options[:url].is_a?(Hash) && !options[:url][:project_id] && custom_value.customized && custom_value.customized.respond_to?(:project)
          if (project = custom_value.customized.project) && !project.easy_is_easy_template?
            options[:url] = options[:url].merge({ :modal_project_id => project.id })
          end
        end

        settings = custom_value.custom_field.settings
        if settings['entity_attribute'] && settings['entity_type']
          entity_class = begin
            ; settings['entity_type'].constantize;
          rescue;
          end
          if settings['entity_attribute'].start_with?('link_with_')
            attribute = EasyEntityAttribute.new(settings['entity_attribute'].sub('link_with_', ''))
          elsif settings['entity_attribute'].to_s == 'name_and_cf'
            cf        = CustomField.find_by_id(settings['entity_custom_field'])
            attribute = EasyEntityNamedCustomAttribute.new(settings['entity_attribute'], cf)
          else
            attribute = EasyEntityAttribute.new(settings['entity_attribute'], { :no_link => true })
          end

          selected_values = {}
          if entity_class && values.any?
            entities = entity_class.where(:id => values).to_a
            values.each do |id|
              next unless entity = entities.detect { |e| e.id == id.to_i }
              attribute_options = options.merge(:entity => entity, :custom_field => cf)

              selected_values[id] = (view.format_html_entity_attribute(entity_class, settings['entity_attribute'], attribute.value(entity), attribute_options) || '').to_s
            end
          end

          options[:multiple]        ||= custom_value.custom_field.multiple? ? '1' : '0'
          options[:custom_field_id] = cf.id if cf
          view.easy_modal_selector_field_tag(settings['entity_type'], settings['entity_attribute'], tag_name, tag_id, selected_values, options)
        end
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, projects = nil, value = '', options = {})
        options[:multiple] ||= custom_field.multiple? ? '1' : '0'
        values             = []
        entity_type        = custom_field.settings['entity_type']
        entity_attribute   = custom_field.settings['entity_attribute']
        view.easy_modal_selector_field_tag(entity_type, entity_attribute, tag_name, tag_id, values, options) + bulk_clear_tag(view, tag_id, tag_name, custom_field, '') if entity_type && entity_attribute
      end

      def cast_single_value(custom_field, value, customized = nil)
        cf_class = target_class_from_custom_field(custom_field)
        cf_class.find_by(:id => value.to_i) if cf_class && value.present?
      end

      def cast_value(custom_field, value, customized = nil)
        if value.is_a?(Array)
          if cf_class = target_class_from_custom_field(custom_field)
            casted = cf_class.where(id: value.map(&:to_i))
            (casted.respond_to?(:sorted) ? casted.sorted : casted.sort).to_a
          end
        else
          super
        end
      end

      def target_class_from_custom_field(custom_field)
        if !@target_class_from_custom_field.nil? && @target_class_from_custom_field.name == custom_field.settings['entity_type']
          @target_class_from_custom_field
        else
          @target_class_from_custom_field = custom_field.settings['entity_type'].constantize
        end
      rescue
      end

      def query_filter_options(custom_field, query)
        klass                = target_class_from_custom_field(custom_field)
        autocomplete_options = { entity: klass.to_s }
        if klass.respond_to?(:additional_select_options)
          additional_select_options                        = klass.additional_select_options
          autocomplete_options[:additional_select_options] = additional_select_options if additional_select_options
        end
        {
            type:                 :list_autocomplete,
            values:               proc { query.objects_for_select("cf_#{custom_field.id}", klass) },
            autocomplete_options: autocomplete_options,
            klass:                klass
        }
      end

      def possible_custom_value_options(custom_value)
        options = possible_values_options(custom_value.custom_field, custom_value.customized)
        missing = [custom_value.value_was].flatten.reject(&:blank?) - options.map(&:last)
        if missing.any? && (entity_class = target_class_from_custom_field(custom_value.custom_field))
          options += entity_class.where(:id => missing.map(&:to_i)).map { |o| [o.to_s, o.id.to_s] }
          options.sort_by!(&:first)
        end
        options
      end

      def order_statement(custom_field)
        cf_class = target_class_from_custom_field(custom_field)
        if cf_class.respond_to?(:fields_for_order_statement)
          cf_class.fields_for_order_statement(value_join_alias(custom_field))
        end
      end

      def join_for_order_statement(custom_field, uniq = true, reference = nil)
        alias_name = join_alias(custom_field)
        reference  ||= "#{custom_field.class.customized_class.table_name}.id"

        result = "LEFT OUTER JOIN #{CustomValue.table_name} #{alias_name}" +
            " ON #{alias_name}.customized_type = '#{custom_field.class.customized_class.base_class.name}'" +
            " AND #{alias_name}.customized_id = #{reference}" +
            " AND #{alias_name}.custom_field_id = #{custom_field.id}" +
            " AND (#{custom_field.visibility_by_project_condition})" +
            " AND #{alias_name}.value <> ''"
        if uniq
          result.concat " AND #{alias_name}.id = (SELECT max(#{alias_name}_2.id) FROM #{CustomValue.table_name} #{alias_name}_2" +
                            " WHERE #{alias_name}_2.customized_type = #{alias_name}.customized_type" +
                            " AND #{alias_name}_2.customized_id = #{alias_name}.customized_id" +
                            " AND #{alias_name}_2.custom_field_id = #{alias_name}.custom_field_id)"
        end

        cf_class = target_class_from_custom_field(custom_field)
        return result if cf_class.nil?

        result.concat " LEFT OUTER JOIN #{cf_class.table_name} #{value_join_alias custom_field}" +
                          " ON CAST(CASE #{alias_name}.value WHEN '' THEN '0' ELSE #{alias_name}.value END AS decimal(30,0)) = #{value_join_alias custom_field}.id"
        result
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        casted_value = cast_value(custom_field, value, customized)
        casted_value = [casted_value] unless casted_value.is_a?(Array) || casted_value.nil?

        settings = custom_field.settings

        entity_class = target_class_from_custom_field(custom_field)
        if settings['entity_attribute'].to_s.start_with?('link_with_')
          attribute = EasyEntityAttribute.new(settings['entity_attribute'].sub('link_with_', ''))
        elsif settings['entity_attribute'].to_s == 'name_and_cf'
          cf        = CustomField.find_by_id(settings['entity_custom_field'])
          attribute = EasyEntityNamedCustomAttribute.new(settings['entity_attribute'], cf)
        else
          attribute = EasyEntityAttribute.new(settings['entity_attribute'].to_s, no_link: true)
        end

        if entity_class && casted_value && !casted_value.blank?
          entities = entity_class.where(id: casted_value).to_a

          selected_values = entities.collect do |entity|
            options = { entity: entity, custom_field: cf, editable: false }

            if html
              view.format_html_entity_attribute(entity_class, settings['entity_attribute'], attribute.value(entity), options)
            else
              view.format_entity_attribute(entity_class, settings['entity_attribute'], attribute.value(entity), options)
            end
          end

          selected_values.compact!
        else
          selected_values = nil
        end

        if html
          selected_values.sort.join(', ').html_safe if selected_values.present?
        elsif casted_value && selected_values.present?
          return selected_values.sort.map { |selected_value| Sanitize.clean(CGI::unescape(selected_value.to_s), output: :html) }.join(', ')
        end
      end

    end

  end
end

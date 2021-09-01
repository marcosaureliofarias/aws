Rys::Patcher.add('CustomFieldsHelper') do
  apply_if_plugins :easy_extensions

  included do
    def easy_computed_from_query_available_formulas(custom_field, query)
      [[]] + custom_field.format.available_formulas(custom_field, query).collect { |f| [l(f, :scope => [:easy_computed_from_query_available_formula]), f] }
    end

    def easy_computed_from_query_available_entity_filters(custom_field, query)
      target_klass = custom_field.class.customized_class
      target_klass_name = target_klass.name.underscore
      res = query.available_filters.select do |filter_id, settings|
        filter_id.include?("#{target_klass_name}.id") || filter_id.include?("#{target_klass_name}_id") ||
          settings[:klass] == target_klass
      end
      res.inject({}) do |acc, filter|
        filter_id = filter.first
        settings = filter.last
        filter_name = settings[:name]
        group_id = settings[:group]
        acc[group_id] ||= []
        acc[group_id] << [filter_name, filter_id]
        acc
      end.to_a
    end

    def options_for_easy_computed_from_query_available_columns(custom_field, query)
      others_group = nil
      grouped_options = custom_field_columns(custom_field, query).group_by(&:group).collect do |k,v|
        group = [k, v.collect {|column| [column.caption(true), column.name]}.sort_by!(&:first)]
        (others_group = group; next) if v.any? && v.first.other_group?
        group
      end.compact
      grouped_options << others_group if others_group
      grouped_options_for_select(grouped_options, custom_field.settings['easy_query_column'], prompt: true)
    end

    def custom_field_columns(custom_field, query)
      custom_field.format.available_columns(custom_field, query).reject do |c|
        c.frozen? || (c.is_a?(EasyQueryCustomFieldColumn) && c.custom_field.field_format == 'easy_computed_from_query')
      end
    end
  end

  instance_methods(feature: 'easy_computed_field_from_query') do
    def custom_field_tag_with_label(name, custom_value, label_tag_options = {}, custom_field_tag_options = {})
      if custom_value.custom_field.field_format == 'easy_computed_from_query'
        cv = custom_value.dup
        cv.value = cv.custom_field.format.formatted_value(self, custom_value.custom_field, custom_value.value, custom_value.customized, false)
        super(name, cv, label_tag_options, custom_field_tag_options.reverse_merge(disabled: true))
      else
        super(name, custom_value, label_tag_options, custom_field_tag_options)
      end
    end
  end

  class_methods do
  end
end

Rys::Patcher.add('Redmine::FieldFormat::ListFormat') do
  apply_if_plugins :easy_extensions
  instance_methods(feature: 'dependent_list_custom_field') do
    def select_edit_tag(view, tag_id, tag_name, custom_value, options = {})
      cf = custom_value.custom_field
      options.merge!('data-dependency' => "#{cf.type.underscore}_#{cf.id}_list")
      super(view, tag_id, tag_name, custom_value, options)
    end
  end
end

module EasyDataTemplatesHelper

  def template_type_options(options={})
    s = []
    s << [l('label_easy_data_template_template_type_import'),"import"] if !options[:only] || (options[:only].include?('import'))
    s << [l('label_easy_data_template_template_type_export'),"export"] if !options[:only] || (options[:only].include?('export'))
    s
  end

  def entity_type_options
    [
      [l('easy_data_template_entity_type_select.EasyDataTemplateProject'), 'EasyDataTemplateProject'],
      [l('easy_data_template_entity_type_select.EasyDataTemplateIssue'), 'EasyDataTemplateIssue'],
      [l('easy_data_template_entity_type_select.EasyDataTemplateTimeEntry'), 'EasyDataTemplateTimeEntry'],
      [l('easy_data_template_entity_type_select.EasyDataTemplateUser'), 'EasyDataTemplateUser']
    ]
  end

  def link_to_data_template(datatemplate)
    if datatemplate.format_type == 'xml' && datatemplate.entity_type.nil?
      link_to(datatemplate.template_type, { :controller => 'easy_data_template_ms_projects', :action => datatemplate.template_type, :id => datatemplate.id})
    else
      link_to(datatemplate.template_type, { :controller => 'easy_data_templates', :action => datatemplate.template_type, :id => datatemplate.id})
    end
  end

  def allowed_import_options
    [[l('easy_data_template_allowed_import_select.xyes'),'yes'],[l('easy_data_template_allowed_import_select.xno'),'no']]
  end

  def apply_to_all_rows_link(element_id, element_class)
    link_to_function '', "apply_to_all_rows('#{element_id}', '#{element_class}')", :class => 'apply-to-all-rows-link icon icon-copy', :title => l(:title_easy_data_templates_apply_to_all_rows)
  end

  def allowed_columns_for_export_for_select(datatemplate)
    [['', '']] + datatemplate.allowed_columns_to_export.collect{|c| [datatemplate.all_allowed_columns[c].caption, c]}
  end

  def allowed_columns_for_import_for_select(datatemplate)
    [['', '']] + datatemplate.allowed_columns_to_import.collect{|c| [datatemplate.all_allowed_columns[c].caption, c]}
  end

  def show_import_preview_value(column_name, column_values, target_project, row_idx)
    s = ''
    selected_entity = column_values[:founded_value]
    empty_array_for_select = [['', '']]
    case column_name
    when 'issue'
      s << get_original_values(column_values)
      s << '<br />'
      s << select_tag("import_data[#{row_idx}][#{column_name}]", options_for_select(empty_array_for_select + target_project.issues.collect{|i| [i.subject, i.id.to_s]}, selected_entity && selected_entity.id.to_s), :onchange => 'CheckPreview()')
    when 'project'
      s << get_original_values(column_values)
      s << '<br />'
      s << select_tag("import_data[#{row_idx}][#{column_name}]", options_for_select(empty_array_for_select + target_project.self_and_descendants.collect{|i| [i.name, i.id.to_s]}, selected_entity && selected_entity.id.to_s), :onchange => 'CheckPreview()')
    when 'activity'
      s << get_original_values(column_values)
      s << '<br />'
      s << select_tag("import_data[#{row_idx}][#{column_name}]", options_for_select(empty_array_for_select + target_project.activities.collect{|a| [a.name, a.id.to_s]}, selected_entity && selected_entity.id.to_s), :onchange => 'CheckPreview()')
    when 'user'
      s << get_original_values(column_values)
      s << '<br />'
      s << select_tag("import_data[#{row_idx}][#{column_name}]", options_for_select(empty_array_for_select + User.active.collect{|u| [u.name, u.id.to_s]}, selected_entity && selected_entity.id.to_s), :onchange => 'CheckPreview()')
    else
      s << text_field_tag("import_data[#{row_idx}][#{column_name}]", column_values[:founded_value], :size => 8, :onchange => 'CheckPreview()')
    end
    s.html_safe
  end

  def get_original_values(column_values)
    column_values[:original_value].collect do |ov|
      s = ''
      s << l(:"easy_data_template_entity_attributes_select.TimeEntry.#{ov[0]}")
      s << ': '
      s << ov[1]
      s
    end.join('<br />')
  end

  def msproject_work_to_estimated_hours(work)
    return nil if work.to_s.blank?
    m = work.match(/^PT(\d+)H(\d+)M(\d+)S$/)
    return nil unless m
    (m[1].to_i + m[2].to_i/60 + m[3].to_i/3600)
  end

end

class EpmProjectInfo < EasyPageModule

  def self.translatable_keys
    [
        %w[heading]
    ]
  end

  def category_name
    @category_name ||= 'projects'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)

      return { :project => project }
    end
  end

  def get_edit_data(settings, user, page_context = {})
    groups         = ['all']
    select_options = [
        [l('select_easy_page_module_project_info.description'), 'description'],
        [l('select_easy_page_module_project_info.customfields'), 'customfields']
    ]
    project        = get_show_data(settings, user, page_context)
    if project && project[:project]
      project[:project].visible_custom_field_values.each do |value|
        if value.custom_field.easy_group && !groups.include?(value.custom_field.easy_group)
          groups << value.custom_field.easy_group
        end
      end
    elsif template_zone_module
      groups.concat(EasyCustomFieldGroup.joins(:custom_fields).where(:custom_fields => { :type => 'ProjectCustomField' }).distinct.to_a)
    end
    { groups: groups, select_options: select_options }
  end

end

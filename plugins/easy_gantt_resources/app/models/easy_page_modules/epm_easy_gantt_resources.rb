class EpmEasyGanttResources < EpmEasyQueryBase

  def category_name
    @category_name ||= 'users'
  end

  def default_settings
    @default_settings ||= { output: 'easy_gantt_resource' }.with_indifferent_access
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_global_easy_gantt)
  end

  def additional_basic_attributes_path
    'easy_page_modules/users/easy_gantt_resources_additional_edit'
  end

  def query_class
    EasyResourceEasyQuery
  end

  def show_preview?
    false
  end

  def show_path
    if RequestStore.store[:epm_easy_gantt_active]
      'easy_gantt/already_active_error'
    else
      RequestStore.store[:epm_easy_gantt_active] = true
      'easy_page_modules/users/easy_gantt_resources_show'
    end
  end

  def page_module_toggling_container_options_helper_method
    'get_epm_easy_gantt_resources_toggling_container_options'
  end

  def get_show_data(settings, user, page_context={})
    query = get_query(settings, user, page_context)

    { query: query }
  end

  def self.async_load
    false
  end

  def self.show_placeholder
    false
  end


end


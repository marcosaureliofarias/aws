class EpmEasyGlobalGantt < EpmEasyQueryBase

  def self.async_load
    false
  end

  def self.show_placeholder
    false
  end

  def category_name
    @category_name ||= 'projects'
  end

  def default_settings
    @default_settings ||= { output: 'easy_gantt' }.with_indifferent_access
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_global_easy_gantt)
  end

  def query_class
    EasyGanttEasyProjectQuery
  end

  def show_path
    if RequestStore.store[:epm_easy_gantt_active]
      'easy_gantt/already_active_error'
    else
      RequestStore.store[:epm_easy_gantt_active] = true
      'easy_page_modules/projects/easy_global_gantt_show'
    end
  end

  def get_show_data(settings, user, **page_context)
    query = get_query(settings, user, page_context)

    { query: query }
  end

end

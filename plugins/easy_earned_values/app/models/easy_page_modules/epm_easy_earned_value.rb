class EpmEasyEarnedValue < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def permissions
    [:view_easy_earned_values]
  end

  def get_show_data(settings, user, **page_context)
    earned_value = EasyEarnedValue.find_by(id: settings['easy_earned_value_id'])

    unless earned_value
      return { error: l(:text_easy_earned_values_select_ev) }
    end

    project = page_context[:project] || earned_value.project

    if !User.current.allowed_to?(:view_easy_earned_values, project)
      return { error: l(:text_easy_earned_values_not_authorized) }
    end

    { earned_value: earned_value }
  end

  def get_edit_data(settings, user, **page_context)
    {}
  end

end

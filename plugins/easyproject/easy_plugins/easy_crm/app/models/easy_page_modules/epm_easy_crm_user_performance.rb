class EpmEasyCrmUserPerformance < EasyPageModule

  def category_name
    @category_name ||= 'easy_crm'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_easy_crms, {})
  end

  def get_show_data(settings, user, page_context = {})
    {}
  end

  def get_edit_data(settings, user, page_context = {})
    scope = User.joins(:members)
    scope = scope.where(:id => user) unless user.allowed_to_globally?(:view_easy_crms, {})
    if page_context[:project]
      scope = scope.where(:members => {:project_id => page_context[:project]})
    else
      scope = scope.where(["#{Member.table_name}.project_id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name = ?)", 'easy_crm'])
    end

    {:users => scope.distinct.active.sorted}
  end

end

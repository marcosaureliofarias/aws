class EpmProjectIssues < EpmIssueQuery

  def show_path
    'easy_page_modules/issues/project_issues_show'
  end

  def edit_path
    'easy_page_modules/issues/project_issues_edit'
  end

  def get_query(settings, user, page_context = {})
    page_context[:project] ||= Project.find_by(:id => page_zone_module.entity_id) if page_zone_module
    settings               = settings.merge('query_type' => '2', 'query_name' => l('easy_pages.modules.project_issues'))
    query                  = super(settings, user, page_context)
    query.add_filter('status_id', 'o', nil) if query
    query
  end

end

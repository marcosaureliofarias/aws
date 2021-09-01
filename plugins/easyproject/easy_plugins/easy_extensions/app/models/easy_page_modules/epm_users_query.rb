class EpmUsersQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'users'
  end

  def permissions
    @permissions ||= [:view_project_overview_users_query]
  end

  def query_class
    EasyMemberQuery
  end

  def get_edit_data(settings, user, page_context = {})
    set_page_context_project(page_context)
    super(settings, user, page_context)
  end

  def get_show_data(settings, user, page_context = {})
    set_page_context_project(page_context)
    super(settings, user, page_context)
  end

  private

  def set_page_context_project(page_context = {})
    if page_context[:project].blank? && page_zone_module && page_zone_module.entity_id
      page_context[:project] = Project.find_by(id: page_zone_module.entity_id)
    end
  end
end

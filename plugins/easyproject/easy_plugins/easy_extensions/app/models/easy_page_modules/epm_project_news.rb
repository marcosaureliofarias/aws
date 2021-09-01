class EpmProjectNews < EasyPageModule

  def permissions
    @permissions ||= [:view_news]
  end

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      news = if (project = page_context[:project] || find_project(page_zone_module.entity_id))
               project.news.preload(:project, :author).order("#{News.table_name}.spinned DESC, #{News.table_name}.created_on DESC").limit(5).all
             else
               []
             end

      { :project => project, :news => news }
    end
  end

  def runtime_permissions(user)
    if page_zone_module && !page_zone_module.entity_id.blank? && (project = find_project(page_zone_module.entity_id))
      user.allowed_to?(:view_news, project)
    else
      true
    end
  end

  def find_project(project_id)
    Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
  end
end

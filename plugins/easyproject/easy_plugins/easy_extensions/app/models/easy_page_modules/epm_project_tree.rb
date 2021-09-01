class EpmProjectTree < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def editable?
    false
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)

      scope    = project.descendants.joins('INNER JOIN projects as children ON children.lft >= projects.lft AND children.rgt <= projects.rgt').where(Project.visible_condition(User.current, table_name: 'children')).group(:id).select(Project.arel_table[Arel.star]).select('(COUNT(children.id) - CASE WHEN MIN(children.lft) > projects.lft THEN 0 ELSE 1 END) AS visible_children').preload(:enabled_modules)
      projects = project.easy_is_easy_template? ? scope.templates : scope.non_templates
      projects = scope.sorted

      { :projects => projects, :project => project }
    end
  rescue ActiveRecord::RecordNotFound
  end

end

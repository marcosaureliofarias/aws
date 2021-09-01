class EpmMyProjectsSimple < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def editable?
    false
  end

  def get_show_data(settings, user, page_context = {})
    projects = Project.visible(user).non_templates.sorted.preload(:enabled_modules, :author)

    { :projects => projects }
  end

  def deprecated?
    true
  end

end

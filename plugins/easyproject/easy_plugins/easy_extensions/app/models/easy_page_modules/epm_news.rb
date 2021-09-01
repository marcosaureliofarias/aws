class EpmNews < EasyPageModule

  def permissions
    @permissions ||= [:view_news]
  end

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})
    scope = News.joins(:project).
        preload(:project, :author, :current_user_read_records, :attachments).
        where(Project.allowed_to_condition(user, :view_news))

    news_count = scope.count
    news       = scope.limit(settings["row_limit"].to_i == 0 ? nil : settings["row_limit"].to_i).order("#{News.table_name}.created_on DESC").all

    { :news_count => news_count, :news => news }
  end

  def get_edit_data(settings, user, page_context = {})
    {}
  end

  def module_allowed?(user = nil)
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = Project.find(page_zone_module.entity_id)
      if project.module_enabled?(:news).nil?
        return false
      end
    end
    super
  end

end

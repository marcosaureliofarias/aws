class EpmIssueQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def query_class
    EasyIssueQuery
  end

  def custom_end_buttons?
    true
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && page_zone_module.settings['daily_snapshot'] == '1'
      super(settings, user, page_context)
    else
      super(settings.merge(query_options: { preload: :favorited_by }), user, page_context)
    end
  end

end

class EpmEasyAlerts < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})

    alert_type = settings['alert_type']
    reports = AlertReport.visible(user).by_type(alert_type).by_rules.sorted unless alert_type.blank?
    reports ||= AlertReport.visible(user).by_rules.sorted

    return {:reports => reports}
  end

end

class EpmChartBaseline < EasyPageModule

  def category_name
    @category_name ||= 'charts'
  end

  def get_show_data(settings, user, page_context = {})
    id       = settings['easy_chart_baseline_id']
    baseline = EasyChartBaseline.visible(user).find_by(id: id)
    return { baseline: baseline }
  end

  def get_edit_data(settings, user, page_context = {})
    { baselines: EasyChartBaseline.visible(user) }
  end

end

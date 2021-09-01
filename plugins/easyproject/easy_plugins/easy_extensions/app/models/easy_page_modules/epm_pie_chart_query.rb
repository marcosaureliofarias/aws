class EpmPieChartQuery < EpmChartQuery

  def primary_renderer(settings, **options)
    'pie'
  end

end

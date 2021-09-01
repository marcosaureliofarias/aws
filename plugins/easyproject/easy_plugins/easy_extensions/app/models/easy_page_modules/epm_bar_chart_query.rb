class EpmBarChartQuery < EpmChartQuery

  def primary_renderer(settings, **options)
    'bar'
  end

end

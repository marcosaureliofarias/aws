class EpmLineChartQuery < EpmChartQuery


  def self.translatable_keys
    result = super
    result << %w[chart_settings additional_queries 0 chart_settings y_label]
    result
  end

  def primary_renderer(settings, **options)
    'line'
  end

end

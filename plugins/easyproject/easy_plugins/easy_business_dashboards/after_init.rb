ActiveSupport.on_load(:easyproject, yield: true) do
  EasyExtensions.global_filters_enabled = true
  EasyExtensions.chart_onclick_enabled = true
end

module EasyBusinessDashboards
  class Hooks < Redmine::Hook::ViewListener

    def easy_extensions_javascripts_hook(context={})
      context[:template].require_asset('global_filters')
      context[:template].require_asset('easy_url_builder')
      context[:template].require_asset('easy_chart_onlick_help')
      context[:template].require_asset('jquery.easy_chart.onclick')
    end

  end
end

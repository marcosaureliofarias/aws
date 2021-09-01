ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), 'app/services')

ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_org_chart/internals'
  require 'easy_org_chart/hooks'
  require 'easy_org_chart/permissions'

  RedmineExtensions::EasySettingPresenter.boolean_keys.concat [
                                                                  :easy_org_chart_show_avatar,
                                                                  :easy_org_chart_show_email,
                                                                  :easy_org_chart_show_user_type
                                                              ]

  if Redmine::Plugin.installed?(:easy_theme_designer)
    EasyThemeDesign::TEMPLATES.concat(['easy_org_chart/easy_org_chart.scss'])
  end
end

Rails.application.configure do
  config.assets.precompile+= %w( html2canvas.js jquery.orgchart.js jquery.debounce.js easy_org_chart_ep2017.css easy_org_chart/application)
end

EpmOrgChart.register_to_all(plugin: :easy_org_chart)

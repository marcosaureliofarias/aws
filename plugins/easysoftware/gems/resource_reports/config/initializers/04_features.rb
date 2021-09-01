Rys::Feature.for_plugin(ResourceReports::Engine) do
  Rys::Feature.add('resource_reports') do
    Redmine::Plugin.installed?(:easy_gantt_resources)
  end
end

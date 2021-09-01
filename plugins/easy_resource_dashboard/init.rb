Redmine::Plugin.register :easy_resource_dashboard do
  if Redmine::Plugin.installed?(:easy_extensions)
    name :easy_resource_dashboard_plugin_name
    author :easy_resource_dashboard_author
    description :easy_resource_dashboard_description
    author_url :easy_resource_dashboard_author_url
  else
    name 'Resource Dashboard'
    author 'Easy Software Ltd'
    author_url 'www.easysoftware.com'
    description 'Resource Dashboard'
  end
  version '1.0.beta'

  requires_redmine_plugin :easy_gantt_resources, version_or_higher: '1.3'

  if Redmine::Plugin.installed?(:easy_extensions)
    categories [:resource]
    depends_on [:easy_gantt_resources]
  end
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end

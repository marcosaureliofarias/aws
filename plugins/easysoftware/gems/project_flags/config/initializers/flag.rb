Rys::Reloader.to_prepare do

  require_dependency 'project_flags/field_formats/flag' if Redmine::Plugin.installed?(:easy_extensions)

end

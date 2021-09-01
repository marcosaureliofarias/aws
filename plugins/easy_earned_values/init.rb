Redmine::Plugin.register :easy_earned_values do
  name 'Easy Earned Values'
  author 'Easy Software Ltd'
  description 'Project management technique for measuring project performance and progress'
  version '2.0'
  url 'www.easyredmine.com'

  requires_redmine_plugin :easy_baseline, version_or_higher: '1.2'

  if Redmine::Plugin.installed?(:easy_extensions)
    depends_on [:easy_baseline]
  end

  # Into easy_settings goes available setting as a symbol key, default value as a value
  settings easy_settings: { }
end

easy_extensions = Redmine::Plugin.registered_plugins[:easy_extensions]

if easy_extensions
  app_dir = File.join(File.dirname(__FILE__), 'app')
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_rake_tasks')
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end

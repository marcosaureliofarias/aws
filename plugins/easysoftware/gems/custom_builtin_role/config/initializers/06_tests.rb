if Rails.env.test? && Redmine::Plugin.installed?(:easy_extensions)
  extensions_skipped = [
    'Project new project from template default role settings for project author user type role present',
  ]
  EasyExtensions::Tests::AllowedFailures.register(extensions_skipped)
end

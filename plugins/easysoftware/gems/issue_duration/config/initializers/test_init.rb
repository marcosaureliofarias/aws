if Redmine::Plugin.installed?(:easy_extensions) && Rails.env.test?
  skipped = [
    'IssuesController journals should not create journal detail when a date column is changed',
  ]
  EasyExtensions::Tests::AllowedFailures.register(skipped) if Redmine::Plugin.installed?(:easy_extensions)
end

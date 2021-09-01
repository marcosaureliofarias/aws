if Redmine::Plugin.installed?(:easy_extensions)
  EasyIntegrations::PeriodicalJob.repeat('*/5 * * * *').perform_later
end

if Redmine::Plugin.installed?(:easy_extensions)
  ActiveSupport.on_load(:easyproject, yield: true) do
    EpmResourceReport.register_to_all
  end

  EasyExtensions::PatchManager.register_easy_page_helper 'ResourceReportHelper'

  require 'resource_reports/utils'
end

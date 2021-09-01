# This file define all features
#
# Rys::Feature.for_plugin(EasyServiceManager::Engine) do
#   Rys::Feature.add('easy_service_manager.project.show')
#   Rys::Feature.add('easy_service_manager.issue.show')
#   Rys::Feature.add('easy_service_manager.time_entries.show')
# end

Rys::Feature.for_plugin(EasyServiceManager::Engine) do
  Rys::Feature.add('easy_service_manager')
end

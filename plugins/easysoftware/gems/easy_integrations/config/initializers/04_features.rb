# This file define all features
#
# Rys::Feature.for_plugin(EasyIntegrations::Engine) do
#   Rys::Feature.add('easy_integrations.project.show')
#   Rys::Feature.add('easy_integrations.issue.show')
#   Rys::Feature.add('easy_integrations.time_entries.show')
# end

Rys::Feature.for_plugin(EasyIntegrations::Engine) do
  Rys::Feature.add('easy_integrations')
end

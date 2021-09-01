# This file define all features
#
# Rys::Feature.for_plugin(EasyApi::Engine) do
#   Rys::Feature.add('easy_api.project.show')
#   Rys::Feature.add('easy_api.issue.show')
#   Rys::Feature.add('easy_api.time_entries.show')
# end

Rys::Feature.for_plugin(EasyApi::Engine) do
  Rys::Feature.add('easy_api')
end

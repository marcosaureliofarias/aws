# This file define all features
#
# Rys::Feature.for_plugin(EasyOauth2::Engine) do
#   Rys::Feature.add('easy_oauth2.project.show')
#   Rys::Feature.add('easy_oauth2.issue.show')
#   Rys::Feature.add('easy_oauth2.time_entries.show')
# end

Rys::Feature.for_plugin(EasyOauth2::Engine) do
  Rys::Feature.add('easy_oauth2')
end

# This file define all features
#
# Rys::Feature.for_plugin(EasySso::Engine) do
#   Rys::Feature.add('easy_sso.project.show')
#   Rys::Feature.add('easy_sso.issue.show')
#   Rys::Feature.add('easy_sso.time_entries.show')
# end

Rys::Feature.for_plugin(EasySso::Engine) do
  Rys::Feature.add('easy_sso')
end

# This file define all features
#
# Rys::Feature.for_plugin(EasyActions::Engine) do
#   Rys::Feature.add('easy_actions.project.show')
#   Rys::Feature.add('easy_actions.issue.show')
#   Rys::Feature.add('easy_actions.time_entries.show')
# end

Rys::Feature.for_plugin(EasyActions::Engine) do
  Rys::Feature.add('easy_actions')
end

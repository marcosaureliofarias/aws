# This file define all features
#
# Rys::Feature.for_plugin(Easy::Redmine::Engine) do
#   Rys::Feature.add('easy.redmine.project.show')
#   Rys::Feature.add('easy.redmine.issue.show')
#   Rys::Feature.add('easy.redmine.time_entries.show')
# end

Rys::Feature.for_plugin(Easy::Redmine::Engine) do
  Rys::Feature.add('easy.redmine')
end

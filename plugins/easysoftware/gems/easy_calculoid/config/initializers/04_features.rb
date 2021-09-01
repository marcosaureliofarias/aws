# This file define all features
#
# Rys::Feature.for_plugin(EasyCalculoid::Engine) do
#   Rys::Feature.add('easy_calculoid.project.show')
#   Rys::Feature.add('easy_calculoid.issue.show')
#   Rys::Feature.add('easy_calculoid.time_entries.show')
# end

Rys::Feature.for_plugin(EasyCalculoid::Engine) do
  Rys::Feature.add('easy_calculoid')
end

# This file define all features
#
# Rys::Feature.for_plugin(ProjectFlags::Engine) do
#   Rys::Feature.add('project_flags.project.show')
#   Rys::Feature.add('project_flags.issue.show')
#   Rys::Feature.add('project_flags.time_entries.show')
# end

Rys::Feature.for_plugin(ProjectFlags::Engine) do
  Rys::Feature.add('project_flags')
end

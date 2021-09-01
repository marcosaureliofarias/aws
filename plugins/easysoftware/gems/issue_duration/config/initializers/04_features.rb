# This file define all features
#
# Rys::Feature.for_plugin(IssueDuration::Engine) do
#   Rys::Feature.add('issue_duration.project.show')
#   Rys::Feature.add('issue_duration.issue.show')
#   Rys::Feature.add('issue_duration.time_entries.show')
# end

Rys::Feature.for_plugin(IssueDuration::Engine) do
  Rys::Feature.add('issue_duration')
end

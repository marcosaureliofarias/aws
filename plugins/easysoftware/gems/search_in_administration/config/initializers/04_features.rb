# This file define all features
#
# Rys::Feature.for_plugin(SearchInAdministration::Engine) do
#   Rys::Feature.add('search_in_administration.project.show')
#   Rys::Feature.add('search_in_administration.issue.show')
#   Rys::Feature.add('search_in_administration.time_entries.show')
# end

Rys::Feature.for_plugin(SearchInAdministration::Engine) do
  Rys::Feature.add('search_in_administration')
end

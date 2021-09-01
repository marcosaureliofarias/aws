# This file define all features
#
# Rys::Feature.for_plugin(EasyWatchersListAutocomplete::Engine) do
#   Rys::Feature.add('easy_watchers_list_autocomplete.project.show')
#   Rys::Feature.add('easy_watchers_list_autocomplete.issue.show')
#   Rys::Feature.add('easy_watchers_list_autocomplete.time_entries.show')
# end

Rys::Feature.for_plugin(EasyWatchersListAutocomplete::Engine) do
  Rys::Feature.add('easy_watchers_list_autocomplete')
end

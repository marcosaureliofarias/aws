# This file define all features
#
# Rys::Feature.for_plugin(ExtendedUsersContextMenu::Engine) do
#   Rys::Feature.add('extended_users_context_menu.project.show')
#   Rys::Feature.add('extended_users_context_menu.issue.show')
#   Rys::Feature.add('extended_users_context_menu.time_entries.show')
# end

Rys::Feature.for_plugin(ExtendedUsersContextMenu::Engine) do
  Rys::Feature.add('extended_users_context_menu')
end

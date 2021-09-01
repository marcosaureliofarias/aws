# This file define all features
#
# Rys::Feature.for_plugin(CustomBuiltinRole::Engine) do
#   Rys::Feature.add('custom_builtin_role.project.show')
#   Rys::Feature.add('custom_builtin_role.issue.show')
#   Rys::Feature.add('custom_builtin_role.time_entries.show')
# end

Rys::Feature.for_plugin(CustomBuiltinRole::Engine) do
  Rys::Feature.add('custom_builtin_role', default_db_status: Rails.env.test?)
end

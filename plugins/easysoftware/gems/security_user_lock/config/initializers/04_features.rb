# This file define all features
#
# Rys::Feature.for_plugin(SecurityUserLock::Engine) do
#   Rys::Feature.add('security_user_lock.project.show')
#   Rys::Feature.add('security_user_lock.issue.show')
#   Rys::Feature.add('security_user_lock.time_entries.show')
# end

Rys::Feature.for_plugin(SecurityUserLock::Engine) do
  Rys::Feature.add('security_user_lock')
end

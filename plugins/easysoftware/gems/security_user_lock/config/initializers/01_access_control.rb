# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_security_user_locks, {
#     security_user_lock: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_security_user_locks, {
#     security_user_lock: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :security_user_lock do |pmap|
#     map.rys_feature('security_user_lock') do |fmap|
#       # View on project
#
#       fmap.permission(:view_security_user_lock, {
#         security_user_lock: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_security_user_lock, {
#         security_user_lock: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

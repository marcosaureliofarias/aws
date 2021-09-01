# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_custom_builtin_roles, {
#     custom_builtin_role: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_custom_builtin_roles, {
#     custom_builtin_role: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :custom_builtin_role do |pmap|
#     map.rys_feature('custom_builtin_role') do |fmap|
#       # View on project
#
#       fmap.permission(:view_custom_builtin_role, {
#         custom_builtin_role: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_custom_builtin_role, {
#         custom_builtin_role: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

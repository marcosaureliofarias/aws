# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_rys_managements, {
#     rys_management: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_rys_managements, {
#     rys_management: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :rys_management do |pmap|
#
#     # View on project
#
#     pmap.permission(:view_rys_management, {
#       rys_management: [:index, :show]
#     }, read: true)
#
#     # Edit on project
#
#     pmap.permission(:manage_rys_management, {
#       rys_management: [:new, :create, :edit, :update, :destroy]
#     }, require: :loggedin)
#
#   end
#
# end

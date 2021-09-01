# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_ryspecs, {
#     ryspec: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_ryspecs, {
#     ryspec: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :ryspec do |pmap|
#
#     # View on project
#
#     pmap.permission(:view_ryspec, {
#       ryspec: [:index, :show]
#     }, read: true)
#
#     # Edit on project
#
#     pmap.permission(:manage_ryspec, {
#       ryspec: [:new, :create, :edit, :update, :destroy]
#     }, require: :loggedin)
#
#   end
#
# end

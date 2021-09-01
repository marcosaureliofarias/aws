# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_easy_cores, {
#     easy_core: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_easy_cores, {
#     easy_core: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_core do |pmap|
#
#     # View on project
#
#     pmap.permission(:view_easy_core, {
#       easy_core: [:index, :show]
#     }, read: true)
#
#     # Edit on project
#
#     pmap.permission(:manage_easy_core, {
#       easy_core: [:new, :create, :edit, :update, :destroy]
#     }, require: :loggedin)
#
#   end
#
# end

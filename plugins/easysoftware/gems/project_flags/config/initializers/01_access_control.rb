# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_project_flags, {
#     project_flags: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_project_flags, {
#     project_flags: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :project_flags do |pmap|
#     map.rys_feature('project_flags') do |fmap|
#       # View on project
#
#       fmap.permission(:view_project_flags, {
#         project_flags: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_project_flags, {
#         project_flags: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

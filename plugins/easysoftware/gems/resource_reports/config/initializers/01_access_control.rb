# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_resource_reports, {
#     resource_reports: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_resource_reports, {
#     resource_reports: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :resource_reports do |pmap|
#     map.rys_feature('resource_reports') do |fmap|
#       # View on project
#
#       fmap.permission(:view_resource_reports, {
#         resource_reports: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_resource_reports, {
#         resource_reports: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

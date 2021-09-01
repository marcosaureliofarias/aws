# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_easy_service_managers, {
#     easy_service_manager: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_easy_service_managers, {
#     easy_service_manager: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_service_manager do |pmap|
#     map.rys_feature('easy_service_manager') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_service_manager, {
#         easy_service_manager: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_service_manager, {
#         easy_service_manager: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

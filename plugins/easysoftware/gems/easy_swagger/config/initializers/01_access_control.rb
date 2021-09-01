# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_swaggers, {
#     easy_swagger: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_swaggers, {
#     easy_swagger: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_swagger do |pmap|
#     map.rys_feature('easy_swagger') do |fmap|
#       # View on project
#
#       fmap.permission(:view_swagger, {
#         easy_swagger: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_swagger, {
#         easy_swagger: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

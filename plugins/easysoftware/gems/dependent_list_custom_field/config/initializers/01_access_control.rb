# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_dependent_list_custom_fields, {
#     dependent_list_custom_field: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_dependent_list_custom_fields, {
#     dependent_list_custom_field: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :dependent_list_custom_field do |pmap|
#     map.rys_feature('dependent_list_custom_field') do |fmap|
#       # View on project
#
#       fmap.permission(:view_dependent_list_custom_field, {
#         dependent_list_custom_field: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_dependent_list_custom_field, {
#         dependent_list_custom_field: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

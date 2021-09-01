# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_extended_users_context_menus, {
#     extended_users_context_menu: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_extended_users_context_menus, {
#     extended_users_context_menu: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :extended_users_context_menu do |pmap|
#     map.rys_feature('extended_users_context_menu') do |fmap|
#       # View on project
#
#       fmap.permission(:view_extended_users_context_menu, {
#         extended_users_context_menu: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_extended_users_context_menu, {
#         extended_users_context_menu: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

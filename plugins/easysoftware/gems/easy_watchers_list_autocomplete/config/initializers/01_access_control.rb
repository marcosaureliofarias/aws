# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_easy_watchers_list_autocompletes, {
#     easy_watchers_list_autocomplete: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_easy_watchers_list_autocompletes, {
#     easy_watchers_list_autocomplete: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_watchers_list_autocomplete do |pmap|
#     map.rys_feature('easy_watchers_list_autocomplete') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_watchers_list_autocomplete, {
#         easy_watchers_list_autocomplete: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_watchers_list_autocomplete, {
#         easy_watchers_list_autocomplete: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

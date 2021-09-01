# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_search_in_administrations, {
#     search_in_administration: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_search_in_administrations, {
#     search_in_administration: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :search_in_administration do |pmap|
#     map.rys_feature('search_in_administration') do |fmap|
#       # View on project
#
#       fmap.permission(:view_search_in_administration, {
#         search_in_administration: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_search_in_administration, {
#         search_in_administration: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

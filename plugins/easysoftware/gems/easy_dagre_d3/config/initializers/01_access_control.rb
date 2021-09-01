# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_easy_dagre_d3s, {
#     easy_dagre_d3: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_easy_dagre_d3s, {
#     easy_dagre_d3: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_dagre_d3 do |pmap|
#     map.rys_feature('easy_dagre_d3') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_dagre_d3, {
#         easy_dagre_d3: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_dagre_d3, {
#         easy_dagre_d3: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

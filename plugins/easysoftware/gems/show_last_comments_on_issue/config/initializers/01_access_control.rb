# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_show_last_comments_on_issues, {
#     show_last_comments_on_issue: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_show_last_comments_on_issues, {
#     show_last_comments_on_issue: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :show_last_comments_on_issue do |pmap|
#
#     # View on project
#
#     pmap.permission(:view_show_last_comments_on_issue, {
#       show_last_comments_on_issue: [:index, :show]
#     }, read: true)
#
#     # Edit on project
#
#     pmap.permission(:manage_show_last_comments_on_issue, {
#       show_last_comments_on_issue: [:new, :create, :edit, :update, :destroy]
#     }, require: :loggedin)
#
#   end
#
# end

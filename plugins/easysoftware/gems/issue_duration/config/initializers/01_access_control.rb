# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_issue_durations, {
#     issue_duration: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_issue_durations, {
#     issue_duration: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :issue_duration do |pmap|
#     map.rys_feature('issue_duration') do |fmap|
#       # View on project
#
#       fmap.permission(:view_issue_duration, {
#         issue_duration: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_issue_duration, {
#         issue_duration: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

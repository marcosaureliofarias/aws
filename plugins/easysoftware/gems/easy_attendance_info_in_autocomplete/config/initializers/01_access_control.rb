# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_easy_attendance_info_in_autocompletes, {
#     easy_attendance_info_in_autocomplete: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_easy_attendance_info_in_autocompletes, {
#     easy_attendance_info_in_autocomplete: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_attendance_info_in_autocomplete do |pmap|
#     map.rys_feature('easy_attendance_info_in_autocomplete') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_attendance_info_in_autocomplete, {
#         easy_attendance_info_in_autocomplete: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_attendance_info_in_autocomplete, {
#         easy_attendance_info_in_autocomplete: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

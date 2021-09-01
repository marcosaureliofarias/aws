# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_email_field_autocompletes, {
#     email_field_autocomplete: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_email_field_autocompletes, {
#     email_field_autocomplete: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :email_field_autocomplete do |pmap|
#     map.rys_feature('email_field_autocomplete') do |fmap|
#       # View on project
#
#       fmap.permission(:view_email_field_autocomplete, {
#         email_field_autocomplete: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_email_field_autocomplete, {
#         email_field_autocomplete: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

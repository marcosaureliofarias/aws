# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_advanced_importers, {
#     advanced_importer: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_advanced_importers, {
#     advanced_importer: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :advanced_importer do |pmap|
#     map.rys_feature('advanced_importer') do |fmap|
#       # View on project
#
#       fmap.permission(:view_advanced_importer, {
#         advanced_importer: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_advanced_importer, {
#         advanced_importer: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

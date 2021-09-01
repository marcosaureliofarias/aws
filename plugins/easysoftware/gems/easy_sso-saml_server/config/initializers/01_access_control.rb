# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_easy_sso_saml_servers, {
#     easy_sso_saml_server: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_easy_sso_saml_servers, {
#     easy_sso_saml_server: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_sso_saml_server do |pmap|
#     map.rys_feature('easy_sso_saml_server') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_sso_saml_server, {
#         easy_sso_saml_server: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_sso_saml_server, {
#         easy_sso_saml_server: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

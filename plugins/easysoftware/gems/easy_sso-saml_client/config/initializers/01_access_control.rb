# Redmine::AccessControl.map do |map|
#
#   # ---------------------------------------------------------------------------
#   # Global level
#
#   # View on global
#
#   map.permission(:view_easy_sso_saml_clients, {
#     easy_sso_saml_client: [:index, :show]
#   }, read: true, global: true)
#
#   # Manage on global
#
#   map.permission(:manage_easy_sso_saml_clients, {
#     easy_sso_saml_client: [:new, :create, :edit, :update, :destroy]
#   }, require: :loggedin, global: true)
#
#   # ---------------------------------------------------------------------------
#   # Project level
#
#   map.project_module :easy_sso_saml_client do |pmap|
#     map.rys_feature('easy_sso_saml_client') do |fmap|
#       # View on project
#
#       fmap.permission(:view_easy_sso_saml_client, {
#         easy_sso_saml_client: [:index, :show]
#       }, read: true)
#
#       # Edit on project
#
#       fmap.permission(:manage_easy_sso_saml_client, {
#         easy_sso_saml_client: [:new, :create, :edit, :update, :destroy]
#       }, require: :loggedin)
#     end
#   end
#
# end

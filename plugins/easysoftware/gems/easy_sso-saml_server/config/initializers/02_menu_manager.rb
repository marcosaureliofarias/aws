# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_sso_saml_server,
#             :easy_sso_saml_servers_path,
#             caption: :label_easy_sso_saml_servers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_sso_saml_server,
#             :easy_sso_saml_servers_path,
#             caption: :label_easy_sso_saml_servers,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_sso_saml_server,
#             :easy_sso_saml_servers_path,
#             caption: :label_easy_sso_saml_servers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

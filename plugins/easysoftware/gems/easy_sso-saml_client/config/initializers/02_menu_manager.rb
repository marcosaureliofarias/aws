# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_sso_saml_client,
#             :easy_sso_saml_clients_path,
#             caption: :label_easy_sso_saml_clients,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_sso_saml_client,
#             :easy_sso_saml_clients_path,
#             caption: :label_easy_sso_saml_clients,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_sso_saml_client,
#             :easy_sso_saml_clients_path,
#             caption: :label_easy_sso_saml_clients,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

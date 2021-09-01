# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_sso,
#             :easy_ssos_path,
#             caption: :label_easy_ssos,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_sso,
#             :easy_ssos_path,
#             caption: :label_easy_ssos,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_sso,
#             :easy_ssos_path,
#             caption: :label_easy_ssos,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

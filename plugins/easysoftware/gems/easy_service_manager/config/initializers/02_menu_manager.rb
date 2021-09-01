# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_service_manager,
#             :easy_service_managers_path,
#             caption: :label_easy_service_managers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_service_manager,
#             :easy_service_managers_path,
#             caption: :label_easy_service_managers,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_service_manager,
#             :easy_service_managers_path,
#             caption: :label_easy_service_managers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

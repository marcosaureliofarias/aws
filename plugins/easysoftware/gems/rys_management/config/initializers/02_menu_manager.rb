# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :rys_management,
#             :rys_managements_path,
#             caption: :label_rys_managements,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :rys_management,
#             :rys_managements_path,
#             caption: :label_rys_managements,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :rys_management,
#             :rys_managements_path,
#             caption: :label_rys_managements,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

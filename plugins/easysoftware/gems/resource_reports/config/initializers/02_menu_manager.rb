# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :resource_reports,
#             :resource_reports_path,
#             caption: :label_resource_reports,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :resource_reports,
#             :resource_reports_path,
#             caption: :label_resource_reports,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :resource_reports,
#             :resource_reports_path,
#             caption: :label_resource_reports,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

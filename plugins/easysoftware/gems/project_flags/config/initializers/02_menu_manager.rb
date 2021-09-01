# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :project_flags,
#             :project_flags_path,
#             caption: :label_project_flags,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :project_flags,
#             :project_flags_path,
#             caption: :label_project_flags,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :project_flags,
#             :project_flags_path,
#             caption: :label_project_flags,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

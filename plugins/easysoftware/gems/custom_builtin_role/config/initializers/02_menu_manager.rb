# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :custom_builtin_role,
#             :custom_builtin_roles_path,
#             caption: :label_custom_builtin_roles,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :custom_builtin_role,
#             :custom_builtin_roles_path,
#             caption: :label_custom_builtin_roles,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :custom_builtin_role,
#             :custom_builtin_roles_path,
#             caption: :label_custom_builtin_roles,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

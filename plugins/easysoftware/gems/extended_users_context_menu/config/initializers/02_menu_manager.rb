# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :extended_users_context_menu,
#             :extended_users_context_menus_path,
#             caption: :label_extended_users_context_menus,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :extended_users_context_menu,
#             :extended_users_context_menus_path,
#             caption: :label_extended_users_context_menus,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :extended_users_context_menu,
#             :extended_users_context_menus_path,
#             caption: :label_extended_users_context_menus,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

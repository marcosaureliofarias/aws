# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :ryspec,
#             :ryspecs_path,
#             caption: :label_ryspecs,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :ryspec,
#             :ryspecs_path,
#             caption: :label_ryspecs,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :ryspec,
#             :ryspecs_path,
#             caption: :label_ryspecs,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

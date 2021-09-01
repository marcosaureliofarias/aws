# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_swagger,
#             :swaggers_path,
#             caption: :label_swaggers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_swagger,
#             :swaggers_path,
#             caption: :label_swaggers,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_swagger,
#             :swaggers_path,
#             caption: :label_swaggers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

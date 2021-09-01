# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_redmine,
#             :easy_redmines_path,
#             caption: :label_easy_redmines,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_redmine,
#             :easy_redmines_path,
#             caption: :label_easy_redmines,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_redmine,
#             :easy_redmines_path,
#             caption: :label_easy_redmines,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

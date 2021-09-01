# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_core,
#             :easy_cores_path,
#             caption: :label_easy_cores,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_core,
#             :easy_cores_path,
#             caption: :label_easy_cores,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_core,
#             :easy_cores_path,
#             caption: :label_easy_cores,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

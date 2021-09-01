# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_jenkins,
#             :easy_jenkins_path,
#             caption: :label_easy_jenkins,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_jenkins,
#             :easy_jenkins_path,
#             caption: :label_easy_jenkins,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_jenkins,
#             :easy_jenkins_path,
#             caption: :label_easy_jenkins,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

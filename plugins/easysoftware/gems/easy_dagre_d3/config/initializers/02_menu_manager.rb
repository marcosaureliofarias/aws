# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_dagre_d3,
#             :easy_dagre_d3s_path,
#             caption: :label_easy_dagre_d3s,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_dagre_d3,
#             :easy_dagre_d3s_path,
#             caption: :label_easy_dagre_d3s,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_dagre_d3,
#             :easy_dagre_d3s_path,
#             caption: :label_easy_dagre_d3s,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

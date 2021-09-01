# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_computed_field_from_query,
#             :easy_computed_field_from_queries_path,
#             caption: :label_easy_computed_field_from_queries,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_computed_field_from_query,
#             :easy_computed_field_from_queries_path,
#             caption: :label_easy_computed_field_from_queries,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_computed_field_from_query,
#             :easy_computed_field_from_queries_path,
#             caption: :label_easy_computed_field_from_queries,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

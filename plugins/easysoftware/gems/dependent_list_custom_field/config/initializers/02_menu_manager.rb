# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :dependent_list_custom_field,
#             :dependent_list_custom_fields_path,
#             caption: :label_dependent_list_custom_fields,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :dependent_list_custom_field,
#             :dependent_list_custom_fields_path,
#             caption: :label_dependent_list_custom_fields,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :dependent_list_custom_field,
#             :dependent_list_custom_fields_path,
#             caption: :label_dependent_list_custom_fields,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

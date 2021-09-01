# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :search_in_administration,
#             :search_in_administrations_path,
#             caption: :label_search_in_administrations,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :search_in_administration,
#             :search_in_administrations_path,
#             caption: :label_search_in_administrations,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :search_in_administration,
#             :search_in_administrations_path,
#             caption: :label_search_in_administrations,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

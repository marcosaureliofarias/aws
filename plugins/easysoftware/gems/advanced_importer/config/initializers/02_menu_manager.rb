# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :advanced_importer,
#             :advanced_importers_path,
#             caption: :label_advanced_importers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :advanced_importer,
#             :advanced_importers_path,
#             caption: :label_advanced_importers,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :advanced_importer,
#             :advanced_importers_path,
#             caption: :label_advanced_importers,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

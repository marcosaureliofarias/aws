# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_oauth2,
#             :easy_oauth2s_path,
#             caption: :label_easy_oauth2s,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_oauth2,
#             :easy_oauth2s_path,
#             caption: :label_easy_oauth2s,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_oauth2,
#             :easy_oauth2s_path,
#             caption: :label_easy_oauth2s,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

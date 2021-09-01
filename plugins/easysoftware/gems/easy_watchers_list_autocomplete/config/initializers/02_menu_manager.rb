# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_watchers_list_autocomplete,
#             :easy_watchers_list_autocompletes_path,
#             caption: :label_easy_watchers_list_autocompletes,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_watchers_list_autocomplete,
#             :easy_watchers_list_autocompletes_path,
#             caption: :label_easy_watchers_list_autocompletes,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_watchers_list_autocomplete,
#             :easy_watchers_list_autocompletes_path,
#             caption: :label_easy_watchers_list_autocompletes,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

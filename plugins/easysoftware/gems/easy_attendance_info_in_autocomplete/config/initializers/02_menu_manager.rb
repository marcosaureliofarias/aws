# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_attendance_info_in_autocomplete,
#             :easy_attendance_info_in_autocompletes_path,
#             caption: :label_easy_attendance_info_in_autocompletes,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_attendance_info_in_autocomplete,
#             :easy_attendance_info_in_autocompletes_path,
#             caption: :label_easy_attendance_info_in_autocompletes,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :easy_attendance_info_in_autocomplete,
#             :easy_attendance_info_in_autocompletes_path,
#             caption: :label_easy_attendance_info_in_autocompletes,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :email_field_autocomplete,
#             :email_field_autocompletes_path,
#             caption: :label_email_field_autocompletes,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :email_field_autocomplete,
#             :email_field_autocompletes_path,
#             caption: :label_email_field_autocompletes,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :email_field_autocomplete,
#             :email_field_autocompletes_path,
#             caption: :label_email_field_autocompletes,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

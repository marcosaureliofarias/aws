# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :issue_duration,
#             :issue_durations_path,
#             caption: :label_issue_durations,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :issue_duration,
#             :issue_durations_path,
#             caption: :label_issue_durations,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :issue_duration,
#             :issue_durations_path,
#             caption: :label_issue_durations,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

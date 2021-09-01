# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :show_last_comments_on_issue,
#             :show_last_comments_on_issues_path,
#             caption: :label_show_last_comments_on_issues,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :show_last_comments_on_issue,
#             :show_last_comments_on_issues_path,
#             caption: :label_show_last_comments_on_issues,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :show_last_comments_on_issue,
#             :show_last_comments_on_issues_path,
#             caption: :label_show_last_comments_on_issues,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :security_user_lock,
#             :security_user_locks_path,
#             caption: :label_security_user_locks,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :security_user_lock,
#             :security_user_locks_path,
#             caption: :label_security_user_locks,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :top_menu do |menu|
#   menu.push :security_user_lock,
#             :security_user_locks_path,
#             caption: :label_security_user_locks,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push(:easy_buttons, :easy_buttons_path, {
    parent: :others,
    if: proc {
      User.current.allowed_to_globally?(:manage_easy_buttons) ||
      User.current.allowed_to_globally?(:manage_own_easy_buttons)
    },
    html: { class: 'icon icon-brick' }
  })
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push(:easy_buttons, :easy_buttons_path, {
    if: proc {
      User.current.allowed_to_globally?(:manage_easy_buttons) ||
      User.current.allowed_to_globally?(:manage_own_easy_buttons)
    },
    html: { class: 'icon icon-brick' }
  })
end

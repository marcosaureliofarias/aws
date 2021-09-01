module ExtendedUsersContextMenu
  class Hooks < ::Redmine::Hook::ViewListener
    render_on :view_users_context_menu_top, partial: 'users/extended_users_context_menu/context_menu_extension_top'
    render_on :view_users_context_menu_bottom, partial: 'users/extended_users_context_menu/context_menu_extension_bottom'
  end
end

require 'rys'

require 'extended_users_context_menu/version'
require 'extended_users_context_menu/engine'

# == Configuration of ExtendedUsersContextMenu
# Static configuration stored in the memory
#
# @example Direct configuration
#   ExtendedUsersContextMenu.config.my_key = 1
#
# @example Configuration via block
#   ExtendedUsersContextMenu.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   ExtendedUsersContextMenu.config.my_key
#
# == Settings for ExtendedUsersContextMenu
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   ExtendedUsersContextMenu.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:extended_users_context_menu_my_value)
#   EasySetting.find_by(name: 'extended_users_context_menu_my_value')
#
# @example Setting
#   ExtendedUsersContextMenu.set_setting(:my_value, VALUE)
#
module ExtendedUsersContextMenu

  # configure do |c|
  #   c.my_key = 'This is my private config for ExtendedUsersContextMenu'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

end

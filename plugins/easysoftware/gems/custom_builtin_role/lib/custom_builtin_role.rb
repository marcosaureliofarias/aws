require 'rys'

require 'custom_builtin_role/version'
require 'custom_builtin_role/engine'

# == Configuration of CustomBuiltinRole
# Static configuration stored in the memory
#
# @example Direct configuration
#   CustomBuiltinRole.config.my_key = 1
#
# @example Configuration via block
#   CustomBuiltinRole.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   CustomBuiltinRole.config.my_key
#
# == Settings for CustomBuiltinRole
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   CustomBuiltinRole.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:custom_builtin_role_my_value)
#   EasySetting.find_by(name: 'custom_builtin_role_my_value')
#
# @example Setting
#   CustomBuiltinRole.set_setting(:my_value, VALUE)
#
module CustomBuiltinRole
  # configure do |c|
  #   c.my_key = 'This is my private config for CustomBuiltinRole'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
end

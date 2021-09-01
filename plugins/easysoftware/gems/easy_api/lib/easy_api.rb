require 'rys'

require 'easy_api/version'
require 'easy_api/engine'

# == Configuration of EasyApi
# Static configuration stored in the memory
#
# @example Direct configuration
#   EasyApi.config.my_key = 1
#
# @example Configuration via block
#   EasyApi.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   EasyApi.config.my_key
#
# == Settings for EasyApi
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   EasyApi.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:easy_api_my_value)
#   EasySetting.find_by(name: 'easy_api_my_value')
#
# @example Setting
#   EasyApi.set_setting(:my_value, VALUE)
#
module EasyApi

  configure do |c|
    # System rys (not visible to the users)
    c.systemic = true
  end

end

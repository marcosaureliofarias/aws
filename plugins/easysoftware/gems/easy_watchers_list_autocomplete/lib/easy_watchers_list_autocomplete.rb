require 'rys'

require 'easy_watchers_list_autocomplete/version'
require 'easy_watchers_list_autocomplete/engine'

# == Configuration of EasyWatchersListAutocomplete
# Static configuration stored in the memory
#
# @example Direct configuration
#   EasyWatchersListAutocomplete.config.my_key = 1
#
# @example Configuration via block
#   EasyWatchersListAutocomplete.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   EasyWatchersListAutocomplete.config.my_key
#
# == Settings for EasyWatchersListAutocomplete
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   EasyWatchersListAutocomplete.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:easy_watchers_list_autocomplete_my_value)
#   EasySetting.find_by(name: 'easy_watchers_list_autocomplete_my_value')
#
# @example Setting
#   EasyWatchersListAutocomplete.set_setting(:my_value, VALUE)
#
module EasyWatchersListAutocomplete
  # configure do |c|
  #   c.my_key = 'This is my private config for EasyWatchersListAutocomplete'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
end

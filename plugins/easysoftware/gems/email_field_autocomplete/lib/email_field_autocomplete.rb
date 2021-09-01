require 'rys'

require 'email_field_autocomplete/version'
require 'email_field_autocomplete/engine'

# == Configuration of EmailFieldAutocomplete
# Static configuration stored in the memory
#
# @example Direct configuration
#   EmailFieldAutocomplete.config.my_key = 1
#
# @example Configuration via block
#   EmailFieldAutocomplete.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   EmailFieldAutocomplete.config.my_key
#
# == Settings for EmailFieldAutocomplete
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   EmailFieldAutocomplete.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:email_field_autocomplete_my_value)
#   EasySetting.find_by(name: 'email_field_autocomplete_my_value')
#
# @example Setting
#   EmailFieldAutocomplete.set_setting(:my_value, VALUE)
#
module EmailFieldAutocomplete
  # configure do |c|
  #   c.my_key = 'This is my private config for EmailFieldAutocomplete'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
end

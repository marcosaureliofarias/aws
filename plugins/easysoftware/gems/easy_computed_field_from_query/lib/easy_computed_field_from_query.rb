require 'rys'

require 'easy_computed_field_from_query/version'
require 'easy_computed_field_from_query/engine'

# == Configuration of EasyComputedFieldFromQuery
# Static configuration stored in the memory
#
# @example Direct configuration
#   EasyComputedFieldFromQuery.config.my_key = 1
#
# @example Configuration via block
#   EasyComputedFieldFromQuery.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   EasyComputedFieldFromQuery.config.my_key
#
# == Settings for EasyComputedFieldFromQuery
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   EasyComputedFieldFromQuery.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:easy_computed_field_from_query_my_value)
#   EasySetting.find_by(name: 'easy_computed_field_from_query_my_value')
#
# @example Setting
#   EasyComputedFieldFromQuery.set_setting(:my_value, VALUE)
#
module EasyComputedFieldFromQuery
  # configure do |c|
  #   c.my_key = 'This is my private config for EasyComputedFieldFromQuery'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
end

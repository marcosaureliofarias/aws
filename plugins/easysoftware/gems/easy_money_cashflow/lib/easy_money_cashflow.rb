require 'rys'

require 'easy_money_cashflow/version'
require 'easy_money_cashflow/engine'

# == Configuration of EasyMoneyCashflow
# Static configuration stored in the memory
#
# @example Direct configuration
#   EasyMoneyCashflow.config.my_key = 1
#
# @example Configuration via block
#   EasyMoneyCashflow.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   EasyMoneyCashflow.config.my_key
#
# == Settings for EasyMoneyCashflow
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   EasyMoneyCashflow.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:easy_money_cashflow_my_value)
#   EasySetting.find_by(name: 'easy_money_cashflow_my_value')
#
# @example Setting
#   EasyMoneyCashflow.set_setting(:my_value, VALUE)
#
module EasyMoneyCashflow
  # configure do |c|
  #   c.my_key = 'This is my private config for EasyMoneyCashflow'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
end

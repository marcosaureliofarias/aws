require 'rys'

require 'resource_reports/version'
require 'resource_reports/engine'

# == Configuration of ResourceReports
# Static configuration stored in the memory
#
# @example Direct configuration
#   ResourceReports.config.my_key = 1
#
# @example Configuration via block
#   ResourceReports.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   ResourceReports.config.my_key
#
# == Settings for ResourceReports
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   ResourceReports.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:resource_reports_my_value)
#   EasySetting.find_by(name: 'resource_reports_my_value')
#
# @example Setting
#   ResourceReports.set_setting(:my_value, VALUE)
#
module ResourceReports
  # configure do |c|
  #   c.my_key = 'This is my private config for ResourceReports'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
end

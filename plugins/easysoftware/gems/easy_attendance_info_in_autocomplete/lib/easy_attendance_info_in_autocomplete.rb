require 'rys'

require 'easy_attendance_info_in_autocomplete/version'
require 'easy_attendance_info_in_autocomplete/engine'

# == Configuration of EasyAttendanceInfoInAutocomplete
# Static configuration stored in the memory
#
# @example Direct configuration
#   EasyAttendanceInfoInAutocomplete.config.my_key = 1
#
# @example Configuration via block
#   EasyAttendanceInfoInAutocomplete.configure do |c|
#     c.my_key = 1
#   end
#
# @example Getting a configuration
#   EasyAttendanceInfoInAutocomplete.config.my_key
#
# == Settings for EasyAttendanceInfoInAutocomplete
# Dynamic settings stored in the DB
# Service methods are defined in the `rys_management`
#
# @example Getting
#   EasyAttendanceInfoInAutocomplete.setting(:my_value)
#
#   # Direct
#   EasySetting.value(:easy_attendance_info_in_autocomplete_my_value)
#   EasySetting.find_by(name: 'easy_attendance_info_in_autocomplete_my_value')
#
# @example Setting
#   EasyAttendanceInfoInAutocomplete.set_setting(:my_value, VALUE)
#
module EasyAttendanceInfoInAutocomplete
  # configure do |c|
  #   c.my_key = 'This is my private config for EasyAttendanceInfoInAutocomplete'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
  def self.show_attendance_info?
    return false unless Rys::Feature.active?('easy_attendance_info_in_autocomplete')
    EasyAttendance.enabled? && User.current.logged? && User.current.allowed_to_globally?(:view_easy_attendances)
  end
end

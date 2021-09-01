# This file define all features
#
# Rys::Feature.for_plugin(EasyAttendanceInfoInAutocomplete::Engine) do
#   Rys::Feature.add('easy_attendance_info_in_autocomplete.project.show')
#   Rys::Feature.add('easy_attendance_info_in_autocomplete.issue.show')
#   Rys::Feature.add('easy_attendance_info_in_autocomplete.time_entries.show')
# end

Rys::Feature.for_plugin(EasyAttendanceInfoInAutocomplete::Engine) do
  Rys::Feature.add('easy_attendance_info_in_autocomplete')
end

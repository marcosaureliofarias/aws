# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks
#
module EasyAttendanceInfoInAutocomplete
  class Hooks < ::Redmine::Hook::ViewListener
    def easy_extensions_javascripts_hook(context = {})
      context[:template].require_asset('easy_attendance_info_in_autocomplete/autocomplete_with_attendance_info.js')
    end

    def application_helper_principals_options_for_autocomplete_collection(context = {})
      if EasyAttendanceInfoInAutocomplete.show_attendance_info?
        load_attendances_for_users(context[:assignables]['Users'] || [])
      end
    end

    def application_helper_principals_options_for_autocomplete_items(context = {})
      if EasyAttendanceInfoInAutocomplete.show_attendance_info?
        return if context[:category] == 'Groups'
        principals_by_id = context[:principals].group_by(&:id)
        context[:autocomplete_items].each do |item|
          assignable = principals_by_id[item[:id]]&.first
          next if assignable.nil?
          if assignable.is_a?(Struct)
            next if assignable.principal.nil?
            assignable = assignable.principal
          end
          if assignable.is_a?(User)
            item[:attendance_status], item[:attendance_status_css] = context[:hook_caller].easy_attendance_indicator(assignable)
          end
        end
      end
    end

    def application_helper_assignables_autocomplete_options_for_edit_bottom(context = {})
      if EasyAttendanceInfoInAutocomplete.show_attendance_info?
        load_attendances_for_users(context[:assignables])
        assignables_by_id = context[:assignables].group_by(&:id)
        context[:autocomplete_items].each do |item|
          assignable = assignables_by_id[item[:id]]&.first
          item[:attendance_status], item[:attendance_status_css] = context[:hook_caller].easy_attendance_indicator(assignable) if assignable.is_a?(User)
        end
      end
    end

    def load_attendances_for_users(users)
      User.load_current_attendance(users)
      User.load_last_today_attendance_to_now(users)
    end
  end
end

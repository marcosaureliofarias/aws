# frozen_string_literal: true

module EasyGraphql
  module Types
    class User < Base

      field :id, ID, null: false
      field :name, String, null: true
      field :avatar_url, String, null: true
      field :attendance_status, String, null: true
      field :attendance_status_css, String, null: true

      def avatar_url
        ::UsersController.helpers.avatar_url(object)
      end

      def attendance_status
        ::EasyAttendancesController.helpers.easy_attendance_indicator(object)[0] if enabled_attendance_status
      end

      def attendance_status_css
        ::EasyAttendancesController.helpers.easy_attendance_indicator(object)[1] if enabled_attendance_status
      end

      def enabled_attendance_status
        object.is_a?(::User) && ::Redmine::Plugin.installed?(:easy_attendances) && ::Rys::Feature.active?('easy_attendance_info_in_autocomplete')
      end

    end
  end
end
